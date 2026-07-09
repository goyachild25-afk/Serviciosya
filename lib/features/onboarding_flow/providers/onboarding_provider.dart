import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/logging_service.dart';

// ─── Provincias de República Dominicana (32) ──────────────────────────────────
const List<String> kProvinciasRD = [
  'Distrito Nacional',
  'Azua',
  'Baoruco',
  'Barahona',
  'Dajabón',
  'Duarte',
  'Elías Piña',
  'El Seibo',
  'Espaillat',
  'Hato Mayor',
  'Hermanas Mirabal',
  'Independencia',
  'La Altagracia',
  'La Romana',
  'La Vega',
  'María Trinidad Sánchez',
  'Monseñor Nouel',
  'Monte Cristi',
  'Monte Plata',
  'Pedernales',
  'Peravia',
  'Puerto Plata',
  'Samaná',
  'Sánchez Ramírez',
  'San Cristóbal',
  'San José de Ocoa',
  'San Juan',
  'San Pedro de Macorís',
  'Santiago',
  'Santiago Rodríguez',
  'Santo Domingo',
  'Valverde',
];

// ─── Categorías de servicios (19) ─────────────────────────────────────────────
const List<Map<String, String>> kServiceCategories = [
  {'id': 'home_cleaning',    'name': 'Limpieza del hogar',               'emoji': '🏠'},
  {'id': 'office_cleaning',  'name': 'Limpieza de oficinas',             'emoji': '🏢'},
  {'id': 'pet_care',         'name': 'Cuidado de mascotas',              'emoji': '🐾'},
  {'id': 'plumbing',         'name': 'Plomería',                         'emoji': '🔧'},
  {'id': 'electrical',       'name': 'Electricidad',                     'emoji': '⚡'},
  {'id': 'painting',         'name': 'Pintura',                          'emoji': '🎨'},
  {'id': 'carpentry',        'name': 'Carpintería',                      'emoji': '🪚'},
  {'id': 'gardening',        'name': 'Jardinería',                       'emoji': '🌿'},
  {'id': 'moving',           'name': 'Mudanzas',                         'emoji': '📦'},
  {'id': 'pest_control',     'name': 'Fumigación',                       'emoji': '🪲'},
  {'id': 'laundry',          'name': 'Lavandería',                       'emoji': '👕'},
  {'id': 'cooking',          'name': 'Cocina / Chef',                    'emoji': '👨‍🍳'},
  {'id': 'babysitting',      'name': 'Cuidado de niños',                 'emoji': '👶'},
  {'id': 'elderly_care',     'name': 'Cuidado de adultos mayores',       'emoji': '👴'},
  {'id': 'appliance_repair', 'name': 'Reparación de electrodomésticos',  'emoji': '🔌'},
  {'id': 'ac_service',       'name': 'Aire acondicionado',               'emoji': '❄️'},
  {'id': 'security',         'name': 'Seguridad y vigilancia',           'emoji': '🔒'},
  {'id': 'car_wash',         'name': 'Lavado de vehículos a domicilio',  'emoji': '🚗'},
  {'id': 'styling',          'name': 'Estilismo a domicilio',            'emoji': '💈'},
];

// ─── Preguntas del cuestionario por categoría ─────────────────────────────────
// Formato: { categoryId: [ {id, text}, ... ] }
// Una categoría queda "habilitada" si el prestador responde "Sí" a AL MENOS UNA pregunta.
const Map<String, List<Map<String, String>>> kCategoryQuestions = {
  'home_cleaning': [
    {'id': 'experiencia',  'text': '¿Tienes experiencia limpiando casas o apartamentos?'},
    {'id': 'equipos',      'text': '¿Cuentas con tus propios equipos y productos de limpieza?'},
  ],
  'office_cleaning': [
    {'id': 'experiencia',    'text': '¿Has realizado limpieza de oficinas o locales comerciales?'},
    {'id': 'disponibilidad', 'text': '¿Tienes disponibilidad en horarios fuera de oficina?'},
  ],
  'pet_care': [
    {'id': 'experiencia',  'text': '¿Tienes experiencia cuidando mascotas de terceros?'},
    {'id': 'conocimiento', 'text': '¿Conoces primeros auxilios básicos para animales?'},
  ],
  'plumbing': [
    {'id': 'experiencia',   'text': '¿Tienes experiencia en instalaciones o reparaciones de plomería?'},
    {'id': 'herramientas',  'text': '¿Cuentas con las herramientas necesarias para trabajos de plomería?'},
  ],
  'electrical': [
    {'id': 'experiencia',   'text': '¿Tienes experiencia en trabajos de instalación eléctrica?'},
    {'id': 'conocimiento',  'text': '¿Conoces las normas de seguridad eléctrica vigentes en RD?'},
  ],
  'painting': [
    {'id': 'experiencia',  'text': '¿Tienes experiencia pintando interiores o exteriores?'},
    {'id': 'herramientas', 'text': '¿Tienes acceso a rodillos, brochas y equipos de pintura?'},
  ],
  'carpentry': [
    {'id': 'experiencia',  'text': '¿Tienes experiencia en trabajos de carpintería?'},
    {'id': 'herramientas', 'text': '¿Cuentas con herramientas de carpintería propias?'},
  ],
  'gardening': [
    {'id': 'experiencia',  'text': '¿Tienes experiencia en jardinería o mantenimiento de áreas verdes?'},
    {'id': 'herramientas', 'text': '¿Tienes herramientas de jardín (podadora, rastrillo, manguera, etc.)?'},
  ],
  'moving': [
    {'id': 'experiencia', 'text': '¿Tienes experiencia realizando mudanzas o transporte de carga?'},
    {'id': 'vehiculo',    'text': '¿Cuentas con vehículo de carga o acceso a uno?'},
  ],
  'pest_control': [
    {'id': 'experiencia',  'text': '¿Tienes experiencia en fumigación o control de plagas?'},
    {'id': 'capacitacion', 'text': '¿Tienes capacitación en el manejo seguro de productos químicos?'},
  ],
  'laundry': [
    {'id': 'experiencia', 'text': '¿Tienes experiencia ofreciendo servicios de lavandería a terceros?'},
    {'id': 'equipos',     'text': '¿Cuentas con lavadora y secadora disponibles para el servicio?'},
  ],
  'cooking': [
    {'id': 'experiencia',  'text': '¿Tienes experiencia cocinando para terceros o en eventos?'},
    {'id': 'conocimiento', 'text': '¿Conoces prácticas básicas de higiene y manipulación de alimentos?'},
  ],
  'babysitting': [
    {'id': 'experiencia',  'text': '¿Tienes experiencia cuidando niños de otras familias?'},
    {'id': 'referencias',  'text': '¿Puedes proveer referencias de familias que han confiado en ti?'},
  ],
  'elderly_care': [
    {'id': 'experiencia',  'text': '¿Tienes experiencia cuidando adultos mayores?'},
    {'id': 'capacitacion', 'text': '¿Has recibido capacitación o tienes conocimientos en asistencia gerontológica?'},
  ],
  'appliance_repair': [
    {'id': 'experiencia',  'text': '¿Tienes experiencia reparando electrodomésticos?'},
    {'id': 'herramientas', 'text': '¿Cuentas con herramientas de diagnóstico y reparación?'},
  ],
  'ac_service': [
    {'id': 'experiencia',  'text': '¿Tienes experiencia instalando o dando mantenimiento a aires acondicionados?'},
    {'id': 'conocimiento', 'text': '¿Conoces el manejo seguro de gases refrigerantes (ej. R-410A)?'},
  ],
  'security': [
    {'id': 'experiencia',  'text': '¿Tienes experiencia en seguridad, vigilancia o guardianía?'},
    {'id': 'referencias',  'text': '¿Puedes proveer referencias de empleos anteriores en seguridad?'},
  ],
  'car_wash': [
    {'id': 'experiencia',  'text': '¿Tienes experiencia lavando vehículos de forma profesional?'},
    {'id': 'herramientas', 'text': '¿Cuentas con equipos de lavado (hidrolavadora, aspiradora, productos, etc.)?'},
  ],
  'styling': [
    {'id': 'experiencia',  'text': '¿Tienes experiencia en barbería, manicure, pedicure o trenzas?'},
    {'id': 'herramientas', 'text': '¿Cuentas con tus propios materiales y herramientas de trabajo?'},
  ],
};

// ─── SharedPreferences helpers ────────────────────────────────────────────────
const String _kOnboardingDonePrefix = 'onboarding_done_';
const String _kVerificationSubmittedPrefix = 'verification_submitted_';

Future<bool> isOnboardingComplete(String userId) async {
  try {
    // Check local cache first (fast)
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('$_kOnboardingDonePrefix$userId') ?? false) {
      LoggingService.info('Onboarding status from cache: true ($userId)');
      return true;
    }

    // Fuente de verdad server-side. Ojo: la fila de `profiles` la crea un
    // trigger de BD automáticamente en el registro, así que su existencia
    // NO significa que el usuario pasó por el setup — con ese criterio,
    // todo prestador recién registrado "ya había terminado" y aterrizaba
    // en un dashboard sin perfil de prestador.
    final profile = await SupabaseService.client
        .from('profiles')
        .select('id, role')
        .eq('id', userId)
        .limit(1)
        .maybeSingle();

    if (profile == null) {
      LoggingService.info('Onboarding status: false — sin perfil ($userId)');
      return false;
    }

    // Prestadores: el setup termina creando su fila en provider_profiles.
    // Esa fila es la señal real de onboarding completado.
    if ((profile['role'] as String? ?? 'client') == 'provider') {
      final providerProfile = await SupabaseService.client
          .from('provider_profiles')
          .select('id')
          .eq('user_id', userId)
          .limit(1)
          .maybeSingle();
      if (providerProfile == null) {
        LoggingService.info(
            'Onboarding status: false — prestador sin provider_profile ($userId)');
        return false;
      }
    }

    await prefs.setBool('$_kOnboardingDonePrefix$userId', true);
    LoggingService.info('Onboarding status from Supabase: true ($userId)');
    return true;
  } catch (e, st) {
    LoggingService.error('isOnboardingComplete failed for user $userId', e, st);
    LoggingService.addError('onboarding_provider', e, st);
    return false;
  }
}

Future<void> markOnboardingComplete(String userId) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('$_kOnboardingDonePrefix$userId', true);
}

Future<bool> isVerificationSubmitted(String userId) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('$_kVerificationSubmittedPrefix$userId') ?? false;
}

Future<void> markVerificationSubmitted(String userId) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('$_kVerificationSubmittedPrefix$userId', true);
}
