import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kanban_board_drag_and_drop/model.dart';
import 'bloc.dart';

class DraggedTask {
  final TaskStatus fromColumn;
  final Task task;
  final int fromIndex;

  const DraggedTask({
    required this.fromColumn,
    required this.task,
    required this.fromIndex,
  });
}

class KanbanBoardWidget extends StatelessWidget {
  const KanbanBoardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<KanbanBoardBloc, KanbanBoardState,
        Map<TaskStatus, List<Task>>>(
      selector: (state) => state.tasksByStatus,
      builder: (context, tasksByStatus) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: TaskStatus.values.map((status) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: _KanbanColumn(
                  status: status,
                  tasks: tasksByStatus[status]!,
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _KanbanColumn extends StatefulWidget {
  final TaskStatus status;
  final List<Task> tasks;

  const _KanbanColumn({required this.status, required this.tasks});

  @override
  State<_KanbanColumn> createState() => _KanbanColumnState();
}

class _KanbanColumnState extends State<_KanbanColumn> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<AnimatedListState> _animatedListKey =
      GlobalKey<AnimatedListState>();

  final double _itemHeight = 108;
  int? _hoverIndex;
  DraggedTask? _currentDrag;
  double _scrollSpeed = 0;
  bool _showScrollHint = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _handleAutoScroll(double dragPosition) {
    const edgeThreshold = 0.2; // 20% of container height
    final viewportHeight = _scrollController.position.viewportDimension;
    final triggerZone = viewportHeight * edgeThreshold;

    final scrollPosition = _scrollController.offset;
    final maxScroll = _scrollController.position.maxScrollExtent;

    if (dragPosition < triggerZone && scrollPosition > 0) {
      _scrollSpeed = (triggerZone - dragPosition) / triggerZone * 20;
      _scrollController
          .jumpTo((scrollPosition - _scrollSpeed).clamp(0, maxScroll));
      setState(() => _showScrollHint = true);
    } else if (dragPosition > viewportHeight - triggerZone &&
        scrollPosition < maxScroll) {
      _scrollSpeed =
          (dragPosition - (viewportHeight - triggerZone)) / triggerZone * 20;
      _scrollController
          .jumpTo((scrollPosition + _scrollSpeed).clamp(0, maxScroll));
      setState(() => _showScrollHint = true);
    } else {
      _scrollSpeed = 0;
      setState(() => _showScrollHint = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              _ColumnHeader(status: widget.status),
              Expanded(
                child: DragTarget<DraggedTask>(
                  onWillAccept: (_) => true,
                  onMove: (details) {
                    final localOffset = details.offset;
                    _handleAutoScroll(localOffset.dy);
                    final adjustedOffset = _getAdjustedOffset(
                      localOffset,
                      _scrollController.offset,
                    );
                    setState(() {
                      _currentDrag = details.data;
                      _hoverIndex = _calculateInsertIndex(adjustedOffset.dy);
                    });
                  },
                  onLeave: (_) => setState(() {
                    _hoverIndex = null;
                    // _currentDrag = null;
                    _showScrollHint = false;
                  }),
                  onAcceptWithDetails: (details) {
                    final adjustedOffset = _getAdjustedOffset(
                      details.offset,
                      _scrollController.offset,
                    );
                    final toIndex = _calculateInsertIndex(adjustedOffset.dy);
                    _handleDrop(details.data, toIndex);
                    setState(() {
                      _hoverIndex = null;
                      _currentDrag = null;
                      _showScrollHint = false;
                    });
                  },
                  builder: (context, candidateData, rejectedData) {
                    var itemCount = _hoverIndex != null
                        ? widget.tasks.length + 1
                        : widget.tasks.length;

                    return Stack(
                      children: [
                        // AnimatedList(
                        //   controller: _scrollController,
                        //   initialItemCount: itemCount,
                        //   itemBuilder: (context, index, animation) {
                        //     if (_hoverIndex != null && index == _hoverIndex) {
                        //       return _buildPlaceholder(animation);
                        //     }

                        //     final originalIndex = _getOriginalIndex(index);
                        //     print(originalIndex);
                        //     return originalIndex < widget.tasks.length
                        //         ? _buildTaskItem(originalIndex, animation)
                        //         : const SizedBox.shrink();
                        //   },
                        // ),

                        ListView.builder(
                          // key: _animatedListKey,
                          controller: _scrollController,
                          itemCount: itemCount,
                          shrinkWrap: true,
                          physics: BouncingScrollPhysics(),
                          itemBuilder: (context, index) {
                            if (_hoverIndex != null && index == _hoverIndex) {
                              return _buildPlaceholder();
                            }

                            final originalIndex = _getOriginalIndex(index);

                            return (originalIndex < widget.tasks.length)
                                ? _buildTaskItem(originalIndex)
                                : const SizedBox.shrink();
                          },
                        ),

                        if (_showScrollHint)
                          Positioned.fill(
                            child: _ScrollHintOverlay(
                              scrollSpeed: _scrollSpeed,
                              viewportHeight: constraints.maxHeight,
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTaskItem(int index) {
    final task = widget.tasks[index];

    if (_currentDrag?.task == task) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8),
      child: Draggable<DraggedTask>(
        data: DraggedTask(
          fromColumn: widget.status,
          task: task,
          fromIndex: index,
        ),
        feedback: Material(
          color: Colors.transparent,
          child: Container(
            width: 300,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: _TaskCard(task: task),
          ),
        ),

        // childWhenDragging: _buildGhostCard(task),
        childWhenDragging: SizedBox.shrink(),
        child: _TaskCard(task: task),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      height: 100,
      width: 300,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: Colors.blue.shade50,
        border: Border.all(color: Colors.blue.shade200, width: 2),
      ),
    );
  }

  // Widget _buildGhostCard(Task task) {
  //   return TweenAnimationBuilder<double>(
  //     duration: const Duration(milliseconds: 200),
  //     tween: Tween(begin: 1, end: 0.4),
  //     builder: (context, value, child) {
  //       return Opacity(
  //         opacity: 0,
  //         child: _TaskCard(task: task),
  //       );
  //     },
  //   );
  // }

  int _getOriginalIndex(int listIndex) {
    return (_hoverIndex != null && listIndex > _hoverIndex!)
        ? listIndex - 1
        : listIndex;
  }

  Offset _getAdjustedOffset(Offset localOffset, double scrollOffset) {
    return Offset(localOffset.dx, localOffset.dy + scrollOffset);
  }

  int _calculateInsertIndex(double verticalOffset) {
    final maxIndex = widget.tasks.length;
    return (verticalOffset / _itemHeight).floor().clamp(0, maxIndex);
  }

  void _handleDrop(DraggedTask draggedTask, int toIndex) {
    if (draggedTask.fromColumn == widget.status) {
      if (toIndex > draggedTask.fromIndex) toIndex--;
      if (toIndex == draggedTask.fromIndex) return;
    }

    context.read<KanbanBoardBloc>().add(
          MoveTaskEvent(
            fromColumn: draggedTask.fromColumn,
            fromIndex: draggedTask.fromIndex,
            toColumn: widget.status,
            toIndex: toIndex,
            task: draggedTask.task,
          ),
        );
  }

  // void _addTask(Task newTask, int index) {
  //   // Insert the task into the list at the specified index
  //   // setState(() {
  //   //   widget.tasks.insert(index, newTask);
  //   // });

  //   // Notify the AnimatedList to insert the item
  //   _animatedListKey.currentState?.insertItem(index);
  // }
}

class _ColumnHeader extends StatelessWidget {
  final TaskStatus status;

  const _ColumnHeader({required this.status});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Text(
            status.name.toUpperCase(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
              letterSpacing: 1.2,
            ),
          ),
          // const SizedBox(width: 8),
          // CircleAvatar(
          //   radius: 10,
          //   backgroundColor: Colors.grey.shade300,
          //   child: Text(
          //     '0', // Replace with actual count
          //     style: const TextStyle(fontSize: 10),
          //   ),
          // ),
        ],
      ),
    );
  }
}

class _ScrollHintOverlay extends StatelessWidget {
  final double scrollSpeed;
  final double viewportHeight;

  const _ScrollHintOverlay(
      {required this.scrollSpeed, required this.viewportHeight});

  @override
  Widget build(BuildContext context) {
    final isScrollingUp = scrollSpeed < 0;
    final opacity = (scrollSpeed.abs() / 20).clamp(0.0, 1.0);

    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: opacity,
        duration: const Duration(milliseconds: 150),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin:
                  isScrollingUp ? Alignment.topCenter : Alignment.bottomCenter,
              end: isScrollingUp ? Alignment.bottomCenter : Alignment.topCenter,
              colors: [
                Colors.white.withOpacity(0.9),
                Colors.white.withOpacity(0.3),
                Colors.transparent,
              ],
              stops: const [0.0, 0.3, 1.0],
            ),
          ),
          child: Align(
            alignment:
                isScrollingUp ? Alignment.topCenter : Alignment.bottomCenter,
            child: Icon(
              isScrollingUp ? Icons.arrow_drop_up : Icons.arrow_drop_down,
              size: 40,
              color: Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final Task task;

  const _TaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      child: Container(
        width: 300,
        constraints: const BoxConstraints(maxWidth: 300, minHeight: 100),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  Icons.drag_handle,
                  size: 18,
                  color: Colors.grey.shade500,
                ),
              ],
            ),
            // if (task.description?.isNotEmpty ?? false)
            //   Padding(
            //     padding: const EdgeInsets.only(top: 8),
            //     child: Text(
            //       task.description!,
            //       style: TextStyle(
            //         fontSize: 12,
            //         color: Colors.grey.shade600,
            //       ),
            //     ),
            //   ),
          ],
        ),
      ),
    );
  }
}
