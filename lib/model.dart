/// Define the statuses as an enum.
enum TaskStatus { open, inProgress, done, onHold }

extension TaskStatusExtension on TaskStatus {
  String get name {
    switch (this) {
      case TaskStatus.open:
        return 'Open';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.done:
        return 'Done';
      case TaskStatus.onHold:
        return 'On Hold';
    }
  }
}

/// Simple Task model.
class Task {
  final String id;
  final String title;

  Task({required this.id, required this.title});

  static get empty => Task(id: '', title: '');
}
