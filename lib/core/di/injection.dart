import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:dead_porky/core/di/injection.config.dart';

/// Global service locator
final getIt = GetIt.instance;

@InjectableInit(preferRelativeImports: true, asExtension: true)
Future<void> configureDependencies() async => getIt.init();
