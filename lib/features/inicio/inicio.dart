/// API pública da feature de início.
library;

export 'estado/disponibilidade_notifier.dart'
    show DisponibilidadeNotifier, EstadoDisponibilidade, disponibilidadeProvider;
export 'estado/turno.dart'
    show pollingLoteProvider, telemetriaProvider, turnoAtivoProvider;
export 'ui/inicio_page.dart' show InicioPage;
export 'ui/monitor_turno.dart' show MonitorTurno;
