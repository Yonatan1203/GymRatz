import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Centralized icon mapping that mirrors the Figma icon library.
/// Every icon used in the app is declared here so that Figma component names
/// map 1-to-1 with code references (e.g. `Icon/ChevronRight` → `AppIcons.chevronRight`).
class AppIcons {
  AppIcons._();

  // ── Navigation ──────────────────────────────────────────────────────
  static const IconData home = LucideIcons.house;
  static const IconData calendar = LucideIcons.calendar;
  static const IconData library = LucideIcons.library;
  static const IconData user = LucideIcons.user;

  // ── Theme ───────────────────────────────────────────────────────────
  static const IconData moon = LucideIcons.moon;
  static const IconData sun = LucideIcons.sun;

  // ── Arrows / Chevrons ──────────────────────────────────────────────
  static const IconData arrowLeft = LucideIcons.arrowLeft;
  static const IconData chevronRight = LucideIcons.chevronRight;
  static const IconData chevronDown = LucideIcons.chevronDown;
  static const IconData chevronUp = LucideIcons.chevronUp;
  static const IconData chevronLeft = LucideIcons.chevronLeft;

  // ── Actions ─────────────────────────────────────────────────────────
  static const IconData plus = LucideIcons.plus;
  static const IconData check = LucideIcons.check;
  static const IconData trash2 = LucideIcons.trash2;
  static const IconData edit = LucideIcons.pencil;
  static const IconData save = LucideIcons.save;
  static const IconData share2 = LucideIcons.share2;
  static const IconData play = LucideIcons.play;
  static const IconData x = LucideIcons.x;

  // ── Achievements / Gamification ────────────────────────────────────
  static const IconData trophy = LucideIcons.trophy;
  static const IconData award = LucideIcons.award;
  static const IconData star = LucideIcons.star;
  static const IconData trendingUp = LucideIcons.trendingUp;
  static const IconData target = LucideIcons.target;
  static const IconData flame = LucideIcons.flame;
  static const IconData crown = LucideIcons.crown;

  // ── Workout / Fitness ──────────────────────────────────────────────
  static const IconData timer = LucideIcons.timer;
  static const IconData clock = LucideIcons.clock;
  static const IconData gripVertical = LucideIcons.gripVertical;
  static const IconData scale = LucideIcons.scale;
  static const IconData repeat = LucideIcons.repeat;
  static const IconData layers = LucideIcons.layers;
  static const IconData barChart2 = LucideIcons.chartBar;
  static const IconData ruler = LucideIcons.ruler;
  static const IconData dumbbell = LucideIcons.dumbbell;

  // ── Health ──────────────────────────────────────────────────────────
  static const IconData heart = LucideIcons.heart;
  static const IconData heartPulse = LucideIcons.heartPulse;

  // ── UI / Misc ──────────────────────────────────────────────────────
  static const IconData zap = LucideIcons.zap;
  static const IconData sparkles = LucideIcons.sparkles;
  static const IconData bell = LucideIcons.bell;
  static const IconData search = LucideIcons.search;
  static const IconData settings = LucideIcons.settings;
  static const IconData filter = LucideIcons.funnel;
  static const IconData download = LucideIcons.download;
  static const IconData info = LucideIcons.info;
  static const IconData helpCircle = LucideIcons.circleQuestionMark;
  static const IconData minimize2 = LucideIcons.minimize2;

  // ── Status ─────────────────────────────────────────────────────────
  static const IconData alertCircle = LucideIcons.circleAlert;
  static const IconData checkCircle = LucideIcons.circleCheck;
  static const IconData minusCircle = LucideIcons.circleMinus;
  static const IconData plusCircle = LucideIcons.circlePlus;

  // ── People / Auth ──────────────────────────────────────────────────
  static const IconData users = LucideIcons.users;
  static const IconData mail = LucideIcons.mail;
  static const IconData camera = LucideIcons.camera;
  static const IconData lock = LucideIcons.lock;
  static const IconData logOut = LucideIcons.logOut;
  static const IconData eye = LucideIcons.eye;
  static const IconData eyeOff = LucideIcons.eyeOff;
  static const IconData shield = LucideIcons.shield;

  // ── Documents ──────────────────────────────────────────────────────
  static const IconData fileText = LucideIcons.fileText;

  // ── Media / Content ────────────────────────────────────────────────
  static const IconData headphones = LucideIcons.headphones;
  static const IconData list = LucideIcons.list;
  static const IconData refreshCw = LucideIcons.refreshCw;
  static const IconData sunrise = LucideIcons.sunrise;
}
