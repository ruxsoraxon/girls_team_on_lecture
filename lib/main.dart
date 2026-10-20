
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: StudyPlannerApp()));
}

// ---------- RIVERPOD STATE MANAGEMENT ----------

class StudyTask {
  final String title;
  final String subject;
  final DateTime dueDate;
  final bool isDone;

  const StudyTask({
    required this.title,
    required this.subject,
    required this.dueDate,
    this.isDone = false,
  });

  StudyTask copyWith({bool? isDone}) {
    return StudyTask(
      title: title,
      subject: subject,
      dueDate: dueDate,
      isDone: isDone ?? this.isDone,
    );
  }
}

class TaskController extends Notifier<List<StudyTask>> {
  @override
  List<StudyTask> build() => [
        StudyTask(
          title: 'Review linear algebra',
          subject: 'Mathematics',
          dueDate: DateTime.now(),
        ),
        StudyTask(
          title: 'Practice Flutter widgets',
          subject: 'Programming',
          dueDate: DateTime.now(),
        ),
        StudyTask(
          title: 'Read physics notes',
          subject: 'Physics',
          dueDate: DateTime.now(),
        ),
      ];

  void addTask(String title, String subject, DateTime dueDate) {
    state = [
      ...state,
      StudyTask(title: title, subject: subject, dueDate: dueDate),
    ];
  }

  void toggleTask(int index) {
    state = [
      for (int i = 0; i < state.length; i++)
        if (i == index) state[i].copyWith(isDone: !state[i].isDone)
        else state[i],
    ];
  }

  void deleteTask(int index) {
    state = [
      for (int i = 0; i < state.length; i++)
        if (i != index) state[i],
    ];
  }
}

final taskProvider =
    NotifierProvider<TaskController, List<StudyTask>>(
  TaskController.new,
);

// ---------- APP ----------

class StudyPlannerApp extends StatelessWidget {
  const StudyPlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Study Planner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
        ),
        useMaterial3: true,
      ),
      home: const DashboardScreen(),
    );
  }
}

// ---------- SCREEN 1: DASHBOARD (setState) ----------

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool showMotivation = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Study Planner')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Your learning journey',
            style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('Plan your work. Track your progress.'),
          const SizedBox(height: 20),
          if (showMotivation)
            Card(
              child: ListTile(
                leading: const Icon(Icons.lightbulb_outline),
                title: const Text('Small steps add up!'),
                subtitle: const Text('Consistency beats cramming.'),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      showMotivation = false;
                    });
                  },
                ),
              ),
            ),
          const SizedBox(height: 12),
          Consumer(
            builder: (context, ref, child) {
              final tasks = ref.watch(taskProvider);
              final completed = tasks.where((t) => t.isDone).length;

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your progress',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text('Total tasks: ${tasks.length}'),
                      Text('Completed: $completed'),
                      Text('Remaining: ${tasks.length - completed}'),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: tasks.isEmpty
                            ? 0
                            : completed / tasks.length,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddTaskScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Add a study task'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const StudyTasksScreen(),
                ),
              );
            },
            icon: const Icon(Icons.checklist),
            label: const Text('View all study tasks'),
          ),
        ],
      ),
    );
  }
}

// ---------- SCREEN 2: ADD TASK (setState) ----------

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();

  final List<String> subjects = [
    'Mathematics',
    'Programming',
    'Physics',
    'Other',
  ];

  String selectedSubject = 'Programming';
  DateTime selectedDate = DateTime.now();

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );

    if (date != null && mounted) {
      setState(() {
        selectedDate = date;
      });
    }
  }

  void saveTask(WidgetRef ref) {
    if (!_formKey.currentState!.validate()) return;

    ref.read(taskProvider.notifier).addTask(
          _titleController.text.trim(),
          selectedSubject,
          selectedDate,
        );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Study task added!')),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Study Task')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'What do you need to study?',
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Task title',
                    hintText: 'e.g. Solve 10 practice problems',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.edit_note),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a task title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: selectedSubject,
                  decoration: const InputDecoration(
                    labelText: 'Subject',
                    border: OutlineInputBorder(),
                  ),
                  items: subjects.map((subject) {
                    return DropdownMenuItem(
                      value: subject,
                      child: Text(subject),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedSubject = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 20),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Study date'),
                  subtitle: Text(
                    '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                  ),
                  trailing: TextButton(
                    onPressed: pickDate,
                    child: const Text('Choose'),
                  ),
                ),
                const SizedBox(height: 24),
                Consumer(
                  builder: (context, ref, child) {
                    return SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => saveTask(ref),
                        icon: const Icon(Icons.save),
                        label: const Text('Save task'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- SCREEN 3: STUDY TASKS (RIVERPOD) ----------

class StudyTasksScreen extends ConsumerWidget {
  const StudyTasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(taskProvider);
    final controller = ref.read(taskProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('My Study Tasks')),
      body: tasks.isEmpty
          ? const Center(
              child: Text('No tasks yet. Add one from the dashboard.'),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];

                return Card(
                  child: ListTile(
                    leading: Checkbox(
                      value: task.isDone,
                      onChanged: (_) => controller.toggleTask(index),
                    ),
                    title: Text(
                      task.title,
                      style: TextStyle(
                        decoration: task.isDone
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                    subtitle: Text(
                      '${task.subject} • '
                      '${task.dueDate.day}/${task.dueDate.month}/${task.dueDate.year}',
                    ),
                    trailing: IconButton(
                      tooltip: 'Delete task',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => controller.deleteTask(index),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
