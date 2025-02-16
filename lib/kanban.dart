import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kanban_board_drag_and_drop/model.dart';

import 'bloc.dart';

/// --- Drag Data --- ///
class DraggedTask {
  final TaskStatus fromColumn;
  final Task task;
  final int fromIndex;

  DraggedTask({
    required this.fromColumn,
    required this.task,
    required this.fromIndex,
  });
}

/// --- Kanban Board UI --- ///
class KanbanBoardWidget extends StatelessWidget {
  const KanbanBoardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<KanbanBoardBloc, KanbanBoardState>(
      builder: (context, state) {
        final Map<TaskStatus, List<Task>> columns = state.tasksByStatus;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: columns.entries.map((entry) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: buildColumn(context, entry.key, entry.value),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  /// Build a single Kanban column.
  Widget buildColumn(
      BuildContext context, TaskStatus status, List<Task> tasks) {
    final columnName = status.name;
    return LayoutBuilder(
      builder: (context, constraints) {
        EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 10);
        final double columnWidth =
            constraints.maxWidth - padding.horizontal; // Get column width
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Column(
            children: [
              // Column header
              Container(
                padding: const EdgeInsets.all(8),
                child: Text(
                  columnName,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(
                height: 1,
                color: Colors.grey,
              ),
              // Task list with drop zones
              Expanded(
                child: ListView.builder(
                  // Use ListView.builder for performance
                  itemCount: tasks.length * 2 + 1, // Drop zones + tasks
                  padding: padding,

                  itemBuilder: (context, index) {
                    if (index % 2 == 0) {
                      // Even index: drop target
                      final dropIndex = index ~/ 2;
                      return DragTarget<DraggedTask>(
                        onWillAcceptWithDetails: (data) => true,
                        onAcceptWithDetails: (draggedTask) {
                          BlocProvider.of<KanbanBoardBloc>(context).add(
                            MoveTaskEvent(
                              fromColumn: draggedTask.data.fromColumn,
                              fromIndex: draggedTask.data.fromIndex,
                              toColumn: status,
                              toIndex: dropIndex,
                              task: draggedTask.data.task,
                            ),
                          );
                        },
                        builder: (context, candidateData, rejectedData) {
                          if (candidateData.isNotEmpty) {
                            return Padding(
                              padding: EdgeInsets.symmetric(vertical: 10),
                              child: Opacity(
                                opacity: 0.5,
                                child: buildTaskCard(
                                    candidateData.first?.task ?? Task.empty,
                                    isDragging: true,
                                    width: columnWidth),
                              ),
                            );
                          }
                          return Container(
                            height: candidateData.isNotEmpty ? 30 : 10,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.withAlpha(30),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        },
                      );
                    } else {
                      // Odd index: draggable task
                      final taskIndex = index ~/ 2;
                      final task = tasks[taskIndex];
                      return Draggable<DraggedTask>(
                        data: DraggedTask(
                          fromColumn: status,
                          task: task,
                          fromIndex: taskIndex,
                        ),
                        feedback: Opacity(
                          opacity: 0.5,
                          child: buildTaskCard(task,
                              isDragging: true, width: columnWidth),
                        ),
                        childWhenDragging: Opacity(
                          opacity: 0.5,
                          child: buildTaskCard(task, width: columnWidth),
                        ),
                        child: buildTaskCard(task, width: columnWidth),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Returns a Card widget representing a task.
  Widget buildTaskCard(Task task,
      {bool isDragging = false, required double width}) {
    return Card(
      elevation: isDragging ? 8.0 : 2.0,
      margin: EdgeInsets.zero,
      color: Colors.white,
      child: Container(
        width: width, // Set card width to match the column
        height: 100,
        padding: const EdgeInsets.all(8.0),
        child: Text(
          task.title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
