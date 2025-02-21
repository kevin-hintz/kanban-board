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
// enum TaskStatus { open, inProgress, done, onHold }

class Task {
  final String id;
  final String title;
  final TaskStatus? status;
  final int? index;

  Task({
    required this.id,
    required this.title,
    this.status,
    this.index,
  });

  Task copyWith({TaskStatus? status, int? index}) {
    return Task(
      id: id,
      title: title,
      status: status ?? this.status,
      index: index ?? this.index,
    );
  }
}
