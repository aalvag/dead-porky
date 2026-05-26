package com.deadporky.app.dead_porky

import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.os.Build
import com.huawei.hmf.tasks.Task
import com.huawei.hms.api.ConnectionResult
import com.huawei.hms.api.HuaweiApiAvailability
import com.huawei.hms.hihealth.DataController
import com.huawei.hms.hihealth.HuaweiHiHealth
import com.huawei.hms.hihealth.SettingController
import com.huawei.hms.hihealth.data.DataType
import com.huawei.hms.hihealth.data.Field
import com.huawei.hms.hihealth.data.SamplePoint
import com.huawei.hms.hihealth.data.SampleSet
import com.huawei.hms.hihealth.data.Scopes
import com.huawei.hms.hihealth.options.ReadOptions
import com.huawei.hms.hihealth.result.ReadReply
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.TimeUnit

class HuaweiHealthKitBridge(
    private val activity: FlutterFragmentActivity,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {
    companion object {
        private const val CHANNEL = "com.deadporky.app/huawei_health_kit"
        private const val REQUEST_AUTH = 0x4857
        private const val SOURCE_LABEL = "Huawei Health Kit"
        private const val NOT_CONFIGURED = "NOT_CONFIGURED"
    }

    private val channel = MethodChannel(messenger, CHANNEL)
    private val settingController: SettingController by lazy {
        HuaweiHiHealth.getSettingController(activity.applicationContext)
    }
    private val dataController: DataController by lazy {
        HuaweiHiHealth.getDataController(activity.applicationContext)
    }

    private var pendingResult: MethodChannel.Result? = null

    init {
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "syncTodayMetrics" -> syncTodayMetrics(result)
            else -> result.notImplemented()
        }
    }

    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_AUTH) {
            return false
        }

        val activeResult = pendingResult ?: return true
        val authResult = settingController.parseHealthKitAuthResultFromIntent(data)

        if (resultCode != android.app.Activity.RESULT_OK || authResult == null) {
            completeWithError(
                code = "auth_cancelled",
                message = "La autorizacion de Huawei Health Kit fue cancelada o no devolvio resultado.",
            )
            return true
        }

        if (!authResult.isSuccess) {
            completeWithError(
                code = "auth_failed",
                message = "Huawei Health Kit no autorizo el acceso a pasos, sueno y frecuencia cardiaca.",
                details = mapOf("errorCode" to authResult.errorCode),
            )
            return true
        }

        queryTodayMetrics(activeResult)
        return true
    }

    private fun syncTodayMetrics(result: MethodChannel.Result) {
        if (pendingResult != null) {
            result.error(
                "busy",
                "Ya hay una sincronizacion de Huawei Health Kit en curso.",
                null,
            )
            return
        }

        val prerequisiteError = checkPrerequisites()
        if (prerequisiteError != null) {
            result.error("unavailable", prerequisiteError, null)
            return
        }

        pendingResult = result

        settingController.getHealthAppAuthorization()
            .addOnSuccessListener { isAuthorized ->
                if (isAuthorized == true) {
                    val activeResult = pendingResult
                    if (activeResult != null) {
                        queryTodayMetrics(activeResult)
                    }
                } else {
                    requestAuthorization()
                }
            }
            .addOnFailureListener {
                requestAuthorization()
            }
    }

    private fun requestAuthorization() {
        try {
            val intent = settingController.requestAuthorizationIntent(
                arrayOf(
                    Scopes.HEALTHKIT_STEP_READ,
                    Scopes.HEALTHKIT_HEARTRATE_READ,
                    Scopes.HEALTHKIT_SLEEP_READ,
                ),
                true,
            )
            activity.startActivityForResult(intent, REQUEST_AUTH)
        } catch (error: Exception) {
            completeWithError(
                code = "authorization_intent_failed",
                message = "No pude abrir la autorizacion de Huawei Health Kit.",
                details = error.message,
            )
        }
    }

    private fun queryTodayMetrics(result: MethodChannel.Result) {
        val nowMillis = System.currentTimeMillis()
        val dayStartMillis = startOfTodayMillis()
        val sleepStartMillis = dayStartMillis - TimeUnit.HOURS.toMillis(18)

        readTodaySteps(
            onSuccess = { steps ->
                readHeartRateAverage(
                    startMillis = dayStartMillis,
                    endMillis = nowMillis,
                    onSuccess = { averageHeartRate ->
                        readLatestRestingHeartRate(
                            onSuccess = { restingHeartRate ->
                                readSleepSummary(
                                    startMillis = sleepStartMillis,
                                    endMillis = nowMillis,
                                    onSuccess = { sleepSummary ->
                                        val availableMetricKeys = buildList {
                                            if (steps > 0) add("steps")
                                            if (sleepSummary.sleepHours > 0 ||
                                                sleepSummary.deepSleepHours > 0 ||
                                                sleepSummary.lightSleepHours > 0 ||
                                                sleepSummary.remSleepHours > 0
                                            ) {
                                                add("sleep")
                                            }
                                            if (restingHeartRate > 0) add("restingHeartRate")
                                            if (averageHeartRate > 0) add("averageHeartRate")
                                        }

                                        val payload = hashMapOf<String, Any>(
                                            "steps" to steps,
                                            "averageHeartRate" to averageHeartRate,
                                            "restingHeartRate" to restingHeartRate,
                                            "sleepHours" to sleepSummary.sleepHours,
                                            "deepSleepHours" to sleepSummary.deepSleepHours,
                                            "lightSleepHours" to sleepSummary.lightSleepHours,
                                            "remSleepHours" to sleepSummary.remSleepHours,
                                            "sourceLabel" to SOURCE_LABEL,
                                            "coverageNote" to buildCoverageNote(availableMetricKeys),
                                            "availableMetricKeys" to availableMetricKeys,
                                        )
                                        completeWithSuccess(payload)
                                    },
                                    onFailure = { error ->
                                        completeWithError(
                                            code = "sleep_read_failed",
                                            message = "Huawei Health Kit no pudo leer el resumen de sueno.",
                                            details = error.message,
                                        )
                                    },
                                )
                            },
                            onFailure = { error ->
                                completeWithError(
                                    code = "resting_hr_read_failed",
                                    message = "Huawei Health Kit no pudo leer la frecuencia cardiaca en reposo.",
                                    details = error.message,
                                )
                            },
                        )
                    },
                    onFailure = { error ->
                        completeWithError(
                            code = "heart_rate_read_failed",
                            message = "Huawei Health Kit no pudo leer la frecuencia cardiaca del dia.",
                            details = error.message,
                        )
                    },
                )
            },
            onFailure = { error ->
                completeWithError(
                    code = "steps_read_failed",
                    message = "Huawei Health Kit no pudo leer los pasos de hoy.",
                    details = error.message,
                )
            },
        )
    }

    private fun readTodaySteps(
        onSuccess: (Int) -> Unit,
        onFailure: (Exception) -> Unit,
    ) {
        dataController.readTodaySummation(DataType.DT_CONTINUOUS_STEPS_DELTA)
            .addOnSuccessListener { sampleSet ->
                onSuccess(extractSteps(sampleSet))
            }
            .addOnFailureListener(onFailure)
    }

    private fun readHeartRateAverage(
        startMillis: Long,
        endMillis: Long,
        onSuccess: (Int) -> Unit,
        onFailure: (Exception) -> Unit,
    ) {
        val readOptions = ReadOptions.Builder()
            .read(DataType.DT_INSTANTANEOUS_HEART_RATE)
            .setTimeRange(startMillis, endMillis, TimeUnit.MILLISECONDS)
            .build()

        dataController.read(readOptions)
            .addOnSuccessListener { readReply ->
                onSuccess(extractAverageHeartRate(readReply))
            }
            .addOnFailureListener(onFailure)
    }

    private fun readLatestRestingHeartRate(
        onSuccess: (Int) -> Unit,
        onFailure: (Exception) -> Unit,
    ) {
        dataController.readLatestData(listOf(DataType.DT_INSTANTANEOUS_RESTING_HEART_RATE))
            .addOnSuccessListener { latestData ->
                val samplePoint = latestData[DataType.DT_INSTANTANEOUS_RESTING_HEART_RATE]
                onSuccess(samplePoint?.let { readIntField(it, Field.FIELD_BPM) } ?: 0)
            }
            .addOnFailureListener(onFailure)
    }

    private fun readSleepSummary(
        startMillis: Long,
        endMillis: Long,
        onSuccess: (SleepSummary) -> Unit,
        onFailure: (Exception) -> Unit,
    ) {
        val readOptions = ReadOptions.Builder()
            .read(DataType.DT_STATISTICS_SLEEP)
            .setTimeRange(startMillis, endMillis, TimeUnit.MILLISECONDS)
            .build()

        dataController.read(readOptions)
            .addOnSuccessListener { readReply ->
                onSuccess(extractSleepSummary(readReply))
            }
            .addOnFailureListener(onFailure)
    }

    private fun extractSteps(sampleSet: SampleSet?): Int {
        val samplePoints = sampleSet?.samplePoints ?: return 0
        return samplePoints.sumOf { samplePoint ->
            readIntField(samplePoint, Field.FIELD_STEPS_DELTA)
                .takeIf { it > 0 }
                ?: readIntField(samplePoint, Field.FIELD_STEPS)
        }
    }

    private fun extractAverageHeartRate(readReply: ReadReply): Int {
        val values = readReply.sampleSets
            .flatMap { it.samplePoints }
            .map { readIntField(it, Field.FIELD_BPM) }
            .filter { it in 40..220 }

        if (values.isEmpty()) {
            return 0
        }

        return values.average().toInt()
    }

    private fun extractSleepSummary(readReply: ReadReply): SleepSummary {
        val latestPoint = readReply.sampleSets
            .flatMap { it.samplePoints }
            .maxByOrNull { it.getEndTime(TimeUnit.MILLISECONDS) }
            ?: return SleepSummary()

        return SleepSummary(
            sleepHours = readDurationHours(latestPoint, Field.ALL_SLEEP_TIME),
            deepSleepHours = readDurationHours(latestPoint, Field.DEEP_SLEEP_TIME),
            lightSleepHours = readDurationHours(latestPoint, Field.LIGHT_SLEEP_TIME),
            remSleepHours = readDurationHours(latestPoint, Field.DREAM_TIME),
        )
    }

    private fun readDurationHours(samplePoint: SamplePoint, field: Field): Double {
        val rawValue = readDoubleField(samplePoint, field)
        return when {
            rawValue <= 0 -> 0.0
            rawValue > 1440.0 -> rawValue / TimeUnit.HOURS.toMillis(1).toDouble()
            rawValue > 24.0 -> rawValue / 60.0
            else -> rawValue
        }
    }

    private fun readIntField(samplePoint: SamplePoint, field: Field): Int {
        return runCatching { samplePoint.getFieldValue(field).asIntValue() }
            .getOrDefault(0)
    }

    private fun readDoubleField(samplePoint: SamplePoint, field: Field): Double {
        return runCatching { samplePoint.getFieldValue(field).asDoubleValue() }
            .getOrElse {
                runCatching { samplePoint.getFieldValue(field).asLongValue().toDouble() }
                    .getOrElse {
                        runCatching { samplePoint.getFieldValue(field).asIntValue().toDouble() }
                            .getOrDefault(0.0)
                    }
            }
    }

    private fun startOfTodayMillis(): Long {
        val now = java.time.ZonedDateTime.now()
        return now.toLocalDate()
            .atStartOfDay(now.zone)
            .toInstant()
            .toEpochMilli()
    }

    private fun buildCoverageNote(availableMetricKeys: List<String>): String {
        if (availableMetricKeys.isEmpty()) {
            return "Fuente actual: $SOURCE_LABEL. Huawei Health Kit se autorizo, pero hoy no devolvio pasos, sueno ni FC."
        }

        val labels = availableMetricKeys.joinToString(", ") { metricKey ->
            when (metricKey) {
                "steps" -> "pasos"
                "sleep" -> "sueno"
                "restingHeartRate" -> "FC reposo"
                "averageHeartRate" -> "FC media"
                else -> metricKey
            }
        }

        return "Fuente actual: $SOURCE_LABEL. Spike Android visible para $labels usando HMS Core."
    }

    private fun checkPrerequisites(): String? {
        if (HuaweiApiAvailability.getInstance()
                .isHuaweiMobileServicesAvailable(activity.applicationContext) != ConnectionResult.SUCCESS
        ) {
            return "HMS Core no esta disponible en este telefono."
        }

        if (!isPackageInstalled("com.huawei.health")) {
            return "Huawei Health no esta instalado en este telefono."
        }

        val appId = resolveHuaweiAppId()
        if (appId.isNullOrBlank() || appId == NOT_CONFIGURED) {
            return "Falta configurar HUAWEI_HEALTH_APP_ID para habilitar Huawei Health Kit en esta app."
        }

        return null
    }

    private fun isPackageInstalled(packageName: String): Boolean {
        return try {
            activity.packageManager.getPackageInfo(packageName, 0)
            true
        } catch (_: PackageManager.NameNotFoundException) {
            false
        }
    }

    private fun resolveHuaweiAppId(): String? {
        return runCatching {
            val applicationInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                activity.packageManager.getApplicationInfo(
                    activity.packageName,
                    PackageManager.ApplicationInfoFlags.of(PackageManager.GET_META_DATA.toLong()),
                )
            } else {
                @Suppress("DEPRECATION")
                activity.packageManager.getApplicationInfo(
                    activity.packageName,
                    PackageManager.GET_META_DATA,
                )
            }
            applicationInfo.metaData?.getString("com.huawei.hms.client.appid")
        }.getOrNull()
    }

    private fun completeWithSuccess(payload: Map<String, Any>) {
        pendingResult?.success(payload)
        pendingResult = null
    }

    private fun completeWithError(
        code: String,
        message: String,
        details: Any? = null,
    ) {
        pendingResult?.error(code, message, details)
        pendingResult = null
    }

    data class SleepSummary(
        val sleepHours: Double = 0.0,
        val deepSleepHours: Double = 0.0,
        val lightSleepHours: Double = 0.0,
        val remSleepHours: Double = 0.0,
    )
}