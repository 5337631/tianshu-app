import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'services/memory_service.dart';
import 'services/background_thinking_service.dart';
import 'services/predict_service.dart';
import 'services/trigger_service.dart';
import 'services/auto_sync_service.dart';
import 'services/ai_service.dart';
import 'services/consciousness_service.dart';
import 'services/config_service.dart';
import 'services/session_logs_service.dart';
import 'services/debugging_service.dart';
import 'services/model_usage_service.dart';
import 'services/channel_config_service.dart';
import 'services/data_processing_service.dart';
import 'services/pdf_qa_service.dart';
import 'services/skill_creator_service.dart';
import 'services/sql_qa_service.dart';
import 'services/youtube_qa_service.dart';
import 'services/agent_team_service.dart';
import 'services/termux_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 并行初始化核心服务（按依赖关系分组）
  // 组1：无依赖的基础服务
  await Future.wait([
    MemoryService.instance.init(),
    ConfigService.instance.init(),
  ]);

  // 组2：依赖组1的服务
  await Future.wait([
    AiService.instance.init(),
    ConsciousnessService.instance.init(),
    SessionLogsService.instance.init(),
    ModelUsageService.instance.init(),
    DebuggingService.instance.init(),
  ]);

  // 组3：依赖 AI 和记忆的服务
  await Future.wait([
    BackgroundThinkingService.instance.init(),
    PredictService.instance.init(),
    TriggerService.instance.init(),
    AutoSyncService.instance.init(),
    ChannelConfigService.instance.init(),
    DataProcessingService.instance.init(),
    PdfQaService.instance.init(),
    SkillCreatorService.instance.init(),
    SqlQaService.instance.init(),
    YoutubeQaService.instance.init(),
    AgentTeamService.instance.init(),
    TermuxService.instance.init(),
  ]);

  runApp(const TianshuApp());
}

class TianshuApp extends StatelessWidget {
  const TianshuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '天枢',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1A1A2E), // 深空蓝
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFFD700), // 星辉金
          secondary: Color(0xFFFFD700),
          surface: Color(0xFF1A1A2E),
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
