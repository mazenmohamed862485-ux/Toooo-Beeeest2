/// TO Best Shared Package
library shared;

// ── Config ────────────────────────────────────────────────────
export 'config/app_config.dart';
export 'config/secrets.dart';

// ── Domain — Entities ─────────────────────────────────────────
export 'domain/entities/user.dart';
export 'domain/entities/workout_session.dart';
export 'domain/entities/nutrition.dart';
export 'domain/entities/chat_message.dart';
export 'domain/entities/health_data.dart';

// ── Domain — Repositories ─────────────────────────────────────
export 'domain/repositories/auth_repository.dart';
export 'domain/repositories/workout_repository.dart';
export 'domain/repositories/nutrition_repository.dart';
export 'domain/repositories/chat_repository.dart';
export 'domain/repositories/health_repository.dart';
export 'domain/repositories/subscription_repository.dart';
export 'domain/repositories/video_repository.dart';

// ── Data — Models ────────────────────────────────────────────
export 'data/models/user_model.dart';
export 'data/models/workout_model.dart';
export 'data/models/food_model.dart';
export 'data/models/chat_model.dart';
export 'data/models/health_model.dart';
export 'data/models/subscription_model.dart';

// ── Infrastructure ────────────────────────────────────────────
export 'infrastructure/gas_client.dart';
export 'infrastructure/isar_service.dart';
export 'infrastructure/sync_service.dart';
export 'infrastructure/video_service.dart';
export 'infrastructure/video_service_drive.dart';
export 'infrastructure/notification_service.dart';
export 'infrastructure/polling_service.dart';
export 'infrastructure/background_service.dart';

// ── Design ────────────────────────────────────────────────────
export 'design/tokens.dart';
export 'design/themes.dart';
export 'design/widgets/breathing_animation.dart';

// ── Utils ─────────────────────────────────────────────────────
export 'utils/evaluator.dart';
export 'utils/extensions.dart';
export 'utils/validators.dart';
