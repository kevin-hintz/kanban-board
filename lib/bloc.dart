import 'package:bloc/bloc.dart';

import 'model.dart';

/// --- BLoC Setup --- ///

/// Kanban board events.
abstract class KanbanBoardEvent {}

/// When a task is moved via drag-and-drop.
class MoveTaskEvent extends KanbanBoardEvent {
  final TaskStatus fromColumn;
  final int fromIndex;
  final TaskStatus toColumn;
  final int toIndex;
  final Task task;

  MoveTaskEvent({
    required this.fromColumn,
    required this.fromIndex,
    required this.toColumn,
    required this.toIndex,
    required this.task,
  });
}

/// The board state holds the tasks organized by their status.
class KanbanBoardState {
  final Map<TaskStatus, List<Task>> tasksByStatus;

  KanbanBoardState({required this.tasksByStatus});

  KanbanBoardState copyWith({Map<TaskStatus, List<Task>>? tasksByStatus}) {
    return KanbanBoardState(
      tasksByStatus: tasksByStatus ?? this.tasksByStatus,
    );
  }
}

/// The bloc that handles moving tasks.
class KanbanBoardBloc extends Bloc<KanbanBoardEvent, KanbanBoardState> {
  KanbanBoardBloc()
      : super(KanbanBoardState(tasksByStatus: {
          TaskStatus.open: List.generate(
            5,
            (index) => Task(
                id: '${index + 1}',
                title: 'Task ${index + 1}',
                status: TaskStatus.open,
                index: index),
          ),
          TaskStatus.inProgress: List.generate(
            5,
            (index) => Task(
                id: '${index + 1}',
                title: 'Task ${index + 1 + 5}',
                status: TaskStatus.inProgress,
                index: index),
          ),
          TaskStatus.done: List.generate(
            5,
            (index) => Task(
                id: '${index + 1}',
                title: 'Task ${index + 1 + 10}',
                status: TaskStatus.done,
                index: index),
          ),
          TaskStatus.onHold: List.generate(
            5,
            (index) => Task(
                id: '${index + 1}',
                title: 'Task ${index + 1 + 15}',
                status: TaskStatus.onHold,
                index: index),
          ),
        })) {
    on<MoveTaskEvent>((event, emit) {
      // Clone the current map to avoid mutating state directly.
      final tasksByStatus =
          Map<TaskStatus, List<Task>>.from(state.tasksByStatus);

      // Remove the task from its originating column.
      final fromList = List<Task>.from(tasksByStatus[event.fromColumn]!);
      fromList.removeAt(event.fromIndex);
      tasksByStatus[event.fromColumn] = fromList;

      // Insert the task into the destination column.
      final toList = List<Task>.from(tasksByStatus[event.toColumn]!);
      toList.insert(event.toIndex, event.task);
      tasksByStatus[event.toColumn] = toList;

      emit(state.copyWith(tasksByStatus: tasksByStatus));
    });
  }
}
