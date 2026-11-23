export type DestinationId =
  | 'about'
  | 'experience'
  | 'projects'
  | 'skills'
  | 'contact';

export interface DestinationConfig {
  id: DestinationId;
  order: number;
  title: string;
  shortLabel: string;
  subtitle: string;
  zoneName: string;
  position: [number, number, number];
  spawnPosition: [number, number];
  spawnHeading: number;
  triggerRadius: number;
  primaryColor: string;
  secondaryColor: string;
  landmarkType: 'monument' | 'pitstop' | 'garage' | 'techzone' | 'finishline';
}

export const DESTINATIONS: DestinationConfig[] = [
  {
    id: 'about',
    order: 1,
    title: 'ABOUT ME',
    shortLabel: 'ABOUT',
    subtitle: 'Driver Profile & Mobile Engineering Bio',
    zoneName: 'North Neon Citadel Plaza',
    position: [0, 0, -84],
    spawnPosition: [0, -64],
    spawnHeading: 0,
    triggerRadius: 22,
    primaryColor: '#38bdf8',
    secondaryColor: '#6366f1',
    landmarkType: 'monument',
  },
  {
    id: 'experience',
    order: 2,
    title: 'EXPERIENCE',
    shortLabel: 'PIT-STOP',
    subtitle: 'Racing Pit-Stop & Career Telemetry',
    zoneName: 'East Racing Pit-Stop Complex',
    position: [126, 0, -56],
    spawnPosition: [106, -68],
    spawnHeading: -Math.PI * 0.65,
    triggerRadius: 22,
    primaryColor: '#a855f7',
    secondaryColor: '#38bdf8',
    landmarkType: 'pitstop',
  },
  {
    id: 'projects',
    order: 3,
    title: 'PROJECTS',
    shortLabel: 'GARAGE',
    subtitle: 'Cyber Showcase Garage & Shipped Builds',
    zoneName: 'South-East Cyber Showcase Garage',
    position: [116, 0, 108],
    spawnPosition: [122, 86],
    spawnHeading: Math.PI * 0.92,
    triggerRadius: 22,
    primaryColor: '#3b82f6',
    secondaryColor: '#ec4899',
    landmarkType: 'garage',
  },
  {
    id: 'skills',
    order: 4,
    title: 'SKILLS',
    shortLabel: 'TECH ZONE',
    subtitle: 'Quantum Tech Arena & Stack Matrix',
    zoneName: 'South-West Quantum Tech Zone',
    position: [-108, 0, 112],
    spawnPosition: [-88, 120],
    spawnHeading: Math.PI * 0.52,
    triggerRadius: 22,
    primaryColor: '#818cf8',
    secondaryColor: '#22d3ee',
    landmarkType: 'techzone',
  },
  {
    id: 'contact',
    order: 5,
    title: 'CONTACT ME',
    shortLabel: 'FINISH',
    subtitle: 'Neon Finish Line & Direct Telemetry',
    zoneName: 'West Grand Neon Finish Line',
    position: [-118, 0, -48],
    spawnPosition: [-122, -26],
    spawnHeading: 0.08,
    triggerRadius: 22,
    primaryColor: '#c084fc',
    secondaryColor: '#38bdf8',
    landmarkType: 'finishline',
  },
];

export const ABOUT_DATA = {
  name: 'Siva Prasad N K',
  role: 'Senior Flutter Developer',
  experience: '3.9+ Years',
  specialization: 'Flutter, Dart, Mobile Application Development',
  location: 'Tripunithura, Ernakulam, Kerala, India',
  photoUrl: `${import.meta.env.BASE_URL}images/propic3.png`,
  resumeUrl: '/resume.pdf',
  intro:
    "I'm Siva Prasad N K, a Senior Flutter Developer with 3.9+ years of experience building responsive, production-grade mobile and web applications with clean architecture, smooth 60 FPS motion, and dependable backend integrations.",
  extendedIntro:
    'From leading Flutter mobile teams and implementing multi-flavor releases with offline caching to shipping interactive WebAssembly & 3D web experiences, I enjoy turning ambitious UI concepts into fast, resilient software. Outside of code, I focus on fitness and quiet moments with my cats.',
  stats: [
    { label: 'Experience', value: '3.9+ Yrs' },
    { label: 'Primary Craft', value: 'Flutter & Dart' },
    { label: 'Architecture', value: 'Clean + BLoC' },
    { label: 'Platforms', value: 'Android · iOS · Web' },
  ],
  highlights: [
    {
      title: 'Cross-Platform UI Precision',
      detail:
        'Crafting silky 60 FPS interfaces, custom painters, responsive layouts, and native-feeling interactions across mobile and web.',
    },
    {
      title: 'Clean Architecture & State Leadership',
      detail:
        'Structuring modular feature layers powered by Bloc, Riverpod, dependency injection, and automated testing.',
    },
    {
      title: 'Production Cloud & Offline Sync',
      detail:
        'Integrating Firebase, Supabase, RESTful APIs, Hive offline persistence, push notifications, and multi-flavor builds.',
    },
    {
      title: 'Automation & Continuous Delivery',
      detail:
        'Streamlining releases to Google Play Store and web targets using GitHub Actions, CI/CD pipelines, and fast iteration.',
    },
  ],
  interests: [
    'Mobile App Architecture',
    'Flutter Performance & Shaders',
    'State Management (Bloc & Riverpod)',
    'Realtime & Offline-First Systems',
    'CI/CD & Developer Tooling',
    'Fitness & Feline Companionship',
  ],
};

export interface ExperienceItem {
  id: string;
  company: string;
  role: string;
  period: string;
  durationTag: string;
  location: string;
  bayNumber: string;
  accent: string;
  responsibilities: string[];
  technologies: string[];
  achievement: string;
}

export const EXPERIENCE_DATA: ExperienceItem[] = [
  {
    id: 'invenics',
    company: 'Invenics Services India Pvt Ltd',
    role: 'Consultant Mobile App Developer',
    period: '05/2023 – 07/2024',
    durationTag: 'BAY 01 · LEAD CONSULTING',
    location: 'Kerala, India',
    bayNumber: 'PIT-01',
    accent: '#a855f7',
    responsibilities: [
      'Led the Flutter mobile development team in designing scalable, maintainable application modules.',
      'Architected multi-environment App Flavoring (dev, staging, production) for seamless QA and release workflows.',
      'Engineered offline-first local persistence and fast cache hydration using Hive DB.',
      'Implemented reliable real-time Push Notifications and deep-link event routing for mobile users.',
    ],
    technologies: [
      'Flutter',
      'Dart',
      'App Flavoring',
      'Hive DB',
      'Push Notifications',
      'REST APIs',
      'Clean Architecture',
    ],
    achievement:
      'Led end-to-end Flutter client delivery with zero-downtime offline support and streamlined multi-flavor builds.',
  },
  {
    id: 'indbytes',
    company: 'Indbytes Technologies Pvt Ltd',
    role: 'Flutter Developer',
    period: '12/2020 – 05/2023',
    durationTag: 'BAY 02 · 2.5 YEARS CORE',
    location: 'Kerala, India',
    bayNumber: 'PIT-02',
    accent: '#38bdf8',
    responsibilities: [
      'Served as Flutter Team Lead mentoring engineers, reviewing pull requests, and owning app quality standards.',
      'Integrated complex RESTful APIs with typed serialization, error recovery, and token management.',
      'Built end-to-end Firebase SDK features including Auth, Cloud Firestore, Analytics, and Cloud Messaging.',
      'Delivered responsive production Android and iOS builds across multiple client verticals.',
    ],
    technologies: [
      'Flutter',
      'Dart',
      'RESTful APIs',
      'Firebase SDK',
      'FCM Push',
      'Bloc / Provider',
      'Git',
    ],
    achievement:
      'Scaled production Flutter apps as Team Lead while establishing reusable API & notification modules.',
  },
  {
    id: 'bayasys',
    company: 'Bayasys Infotech Pvt Ltd',
    role: 'Programmer Trainee',
    period: '07/2019 – 09/2020',
    durationTag: 'BAY 03 · FOUNDATIONS',
    location: 'Kerala, India',
    bayNumber: 'PIT-03',
    accent: '#6366f1',
    responsibilities: [
      'Developed enterprise application features using Java and PostgreSQL relational schemas.',
      'Conducted direct on-site client visits to gather requirements, debug workflows, and deploy updates.',
      'Wrote optimized SQL queries and data-validation routines for business-critical records.',
    ],
    technologies: ['Java', 'PostgreSQL', 'SQL', 'Client Consultation'],
    achievement:
      'Built strong backend and relational data fundamentals alongside real-world client engineering communication.',
  },
];

export interface ProjectItem {
  id: string;
  name: string;
  category: string;
  tagline: string;
  description: string;
  features: string[];
  technologies: string[];
  previewImage?: string;
  previewGradient: string;
  accentColor: string;
  githubUrl: string;
  liveUrl?: string;
  playStoreUrl?: string;
}

export const PROJECTS_DATA: ProjectItem[] = [
  {
    id: 'qrcode-studio',
    name: 'QR Code Studio',
    category: 'Android & Web Utility',
    tagline: 'Custom-styled QR Code Generator & Real-time Scanner',
    description:
      'Cross-platform QR Code Studio shipped for Android (Google Play) and Web with customizable data modules, eye shapes, dynamic themes, PNG export, and real-time camera scanning.',
    features: [
      'Custom body dot styles, corner eye shapes & dynamic gradients',
      'Real-time camera & gallery QR scanner in browser and mobile',
      'High-resolution PNG export & one-tap sharing',
    ],
    technologies: ['Flutter', 'Dart', 'Android', 'Web', 'QR Engine'],
    previewGradient: 'from-cyan-500/30 via-blue-600/20 to-indigo-900/60',
    accentColor: '#38bdf8',
    githubUrl: 'https://github.com/sivaprasadnk/',
    liveUrl: 'https://sivaprasadnk.dev/qrcode',
    playStoreUrl:
      'https://play.google.com/store/apps/details?id=dev.sivaprasadnk.qr_code_studio_mobile',
  },
  {
    id: 'portfolio-webapp',
    name: 'Interactive Portfolio Ecosystem',
    category: 'Web & 3D Graphics',
    tagline: 'Multi-experience Developer Portfolio (Bento / 3D Racer / 3D Solar)',
    description:
      'Personal interactive portfolio suite uniting an architectural Bento Grid (/), this AAA React Three Fiber 3D Racing Game (/v2), and a 3D Orbital Solar System (/v3).',
    features: [
      'Clean Architecture with Bloc state management & multi-view routing',
      'Hardware-accelerated WebGL Three.js / React Three Fiber 3D experiences',
      'Responsive desktop & mobile gameplay with custom shaders & bloom',
    ],
    technologies: ['Flutter', 'React', 'Three.js', 'TypeScript', 'Tailwind CSS'],
    previewImage: `${import.meta.env.BASE_URL}images/website.png`,
    previewGradient: 'from-blue-600/30 via-purple-600/25 to-slate-950/70',
    accentColor: '#60a5fa',
    githubUrl: 'https://github.com/sivaprasadnk/',
    liveUrl: 'https://sivaprasadnk.dev/',
  },
  {
    id: 'arcade-hub',
    name: 'SPNK Arcade Hub',
    category: 'Interactive Web Games',
    tagline: '60 FPS Multi-Game Canvas Arcade Suite',
    description:
      'Multi-game browser arcade featuring Neon Snake, 2048, Cyber Breaker, and Memory Matrix built with custom 60 FPS canvas physics and full keyboard/touch D-pad support.',
    features: [
      'Custom 60 FPS game loops & collision physics',
      'Neon cyber visual feedback & score persistence',
      'Unified WASD/Arrow keys, mouse & mobile touch controls',
    ],
    technologies: ['Flutter Web', 'Canvas 2D', 'Dart', 'Game Physics'],
    previewGradient: 'from-fuchsia-500/30 via-purple-600/20 to-slate-900/70',
    accentColor: '#e879f9',
    githubUrl: 'https://github.com/sivaprasadnk/',
    liveUrl: 'https://sivaprasadnk.dev/arcade',
  },
  {
    id: 'yt-downloader',
    name: 'YouTube Media Studio',
    category: 'WebAssembly Media Tool',
    tagline: '4K/1080p60 Video & Lossless Audio Downloader',
    description:
      'WebAssembly-powered media extractor supporting 4K & 1080p60 MP4+AAC client-side muxing, direct Opus/M4A & 16-bit PCM WAV audio extraction, MaxRes thumbnails, and WebVTT subtitles.',
    features: [
      'Client-side media stream muxing & 16-bit PCM WAV export',
      'MaxRes HD thumbnail downloader & subtitle extractor',
      'Clean telemetry progress & responsive WebAssembly execution',
    ],
    technologies: ['Flutter', 'WebAssembly', 'REST APIs', 'Audio/Video Mux'],
    previewGradient: 'from-indigo-500/30 via-cyan-500/20 to-slate-950/70',
    accentColor: '#818cf8',
    githubUrl: 'https://github.com/sivaprasadnk/',
    liveUrl: 'https://sivaprasadnk.dev/yt-downloader',
  },
  {
    id: 'sp-quiz-app',
    name: 'SP Quiz App',
    category: 'Published Mobile App',
    tagline: 'Dynamic Multi-Theme Quiz Application on Google Play',
    description:
      'Engaging Android quiz application published on Google Play Store featuring customizable color themes, light/dark modes, category challenges, and favorite question bookmarking.',
    features: [
      'Dynamic multi-palette theme engine & adaptive dark mode',
      'Favorite questions bookmarking & instant score breakdown',
      'Clean Provider state management architecture',
    ],
    technologies: ['Flutter', 'Firebase', 'Provider', 'Android'],
    previewImage: `${import.meta.env.BASE_URL}images/quiz_app.png`,
    previewGradient: 'from-violet-500/30 via-blue-500/20 to-slate-950/70',
    accentColor: '#a855f7',
    githubUrl: 'https://github.com/sivaprasadnk/',
    playStoreUrl:
      'https://play.google.com/store/apps/details?id=com.sptpra.spquiz',
  },
  {
    id: 'sp-quotes-app',
    name: 'SP Quotes App',
    category: 'Published Mobile App',
    tagline: 'Glassmorphic Inspiration Discovery App on Google Play',
    description:
      'Curated quotes reading experience with modern Glassmorphism UI, REST API feed synchronization, gallery card export, and native social sharing.',
    features: [
      'Frost-glass visual cards with smooth category browsing',
      'One-tap save to device gallery & social sharing',
      'Lightweight Provider state orchestration & API caching',
    ],
    technologies: ['Flutter', 'Public APIs', 'Provider', 'Glassmorphism UI'],
    previewImage: `${import.meta.env.BASE_URL}images/quotes_app.png`,
    previewGradient: 'from-sky-500/30 via-indigo-500/20 to-slate-950/70',
    accentColor: '#22d3ee',
    githubUrl: 'https://github.com/sivaprasadnk/',
    playStoreUrl:
      'https://play.google.com/store/apps/details?id=com.sptpra.spquotes',
  },
];

export interface SkillItem {
  id: string;
  name: string;
  category: 'Core' | 'State & Arch' | 'Backend & Cloud' | 'DevOps & Delivery';
  level: number;
  years: string;
  color: string;
  summary: string;
}

export const SKILLS_DATA: SkillItem[] = [
  {
    id: 'flutter',
    name: 'Flutter',
    category: 'Core',
    level: 96,
    years: '3.9+ yrs',
    color: '#38bdf8',
    summary:
      'Production cross-platform apps (Android, iOS, Web) with CustomPainter, shaders, and 60 FPS animations.',
  },
  {
    id: 'dart',
    name: 'Dart',
    category: 'Core',
    level: 96,
    years: '3.9+ yrs',
    color: '#22d3ee',
    summary:
      'Sound null-safe, strongly typed asynchronous programming, isolates, streams, and clean domain modeling.',
  },
  {
    id: 'firebase',
    name: 'Firebase',
    category: 'Backend & Cloud',
    level: 90,
    years: '3.5+ yrs',
    color: '#f59e0b',
    summary:
      'Auth, Cloud Firestore, Realtime DB, FCM push notifications, Crashlytics, and remote configuration.',
  },
  {
    id: 'supabase',
    name: 'Supabase',
    category: 'Backend & Cloud',
    level: 84,
    years: '1.5+ yrs',
    color: '#34d399',
    summary:
      'PostgreSQL row-level security, realtime subscriptions, edge functions, and storage integration.',
  },
  {
    id: 'nodejs',
    name: 'Node.js',
    category: 'Backend & Cloud',
    level: 80,
    years: '2+ yrs',
    color: '#4ade80',
    summary:
      'REST microservices, Express APIs, webhook handlers, and backend tooling for mobile clients.',
  },
  {
    id: 'rest-apis',
    name: 'REST APIs',
    category: 'Backend & Cloud',
    level: 94,
    years: '3.9+ yrs',
    color: '#60a5fa',
    summary:
      'Typed HTTP clients, interceptors, JWT refresh flows, pagination, and resilient offline fallback caching.',
  },
  {
    id: 'riverpod',
    name: 'Riverpod',
    category: 'State & Arch',
    level: 90,
    years: '2+ yrs',
    color: '#818cf8',
    summary:
      'Compile-safe reactive providers, AsyncNotifier controllers, granular rebuild scoping, and testable DI.',
  },
  {
    id: 'bloc',
    name: 'Bloc',
    category: 'State & Arch',
    level: 93,
    years: '3.5+ yrs',
    color: '#a855f7',
    summary:
      'Predictable event-driven state machines, Cubits, Equatable states, and strict presentation separation.',
  },
  {
    id: 'clean-architecture',
    name: 'Clean Architecture',
    category: 'State & Arch',
    level: 92,
    years: '3.5+ yrs',
    color: '#c084fc',
    summary:
      'Layered Data/Domain/Presentation boundaries, repository contracts, use cases, and GetIt service location.',
  },
  {
    id: 'github-actions',
    name: 'GitHub Actions',
    category: 'DevOps & Delivery',
    level: 85,
    years: '2.5+ yrs',
    color: '#93c5fd',
    summary:
      'Automated analyze, widget/unit test gates, web Wasm builds, and tagged multi-flavor artifacts.',
  },
  {
    id: 'cicd',
    name: 'CI/CD',
    category: 'DevOps & Delivery',
    level: 86,
    years: '2.5+ yrs',
    color: '#e879f9',
    summary:
      'Continuous integration checks, automated Play Store & GitHub Pages deployments, and release versioning.',
  },
];

export const CONTACT_DATA = {
  finishMessage: "Let's Build Something Amazing Together!",
  email: 'sivaprasadnk.official@gmail.com',
  phone: '+91 8086028340',
  location: 'Tripunithura, Ernakulam, Kerala, India',
  linkedin: 'https://www.linkedin.com/in/sivaprasadnkofficial/',
  github: 'https://github.com/sivaprasadnk/',
  portfolioLinks: [
    {
      label: 'Interactive Grid Portfolio (/)',
      url: '/',
      external: false,
    },
    {
      label: '3D Solar System Portfolio (/v3)',
      url: '/v3/',
      external: false,
    },
    {
      label: 'VS Code Themes Publisher',
      url: 'https://marketplace.visualstudio.com/publishers/SivaprasadNK',
      external: true,
    },
    {
      label: 'pub.dev Verified Publisher',
      url: 'https://pub.dev/publishers/sivaprasadnk.dev/packages',
      external: true,
    },
    {
      label: 'Download Resume (PDF)',
      url: '/resume.pdf',
      external: true,
    },
  ],
};
