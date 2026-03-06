import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../viewmodels/todo_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../models/todo_model.dart';

class TodoListView extends StatefulWidget {
  const TodoListView({super.key});

  @override
  State<TodoListView> createState() => _TodoListViewState();
}

class _TodoListViewState extends State<TodoListView>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  String _searchQuery = '';
  String _sortBy = 'created';
  bool _showCompleted = true;

  static const Color zinc950 = Color(0xFF09090b);
  static const Color zinc900 = Color(0xFF18181b);
  static const Color zinc800 = Color(0xFF27272a);
  static const Color zinc700 = Color(0xFF3f3f46);
  static const Color zinc400 = Color(0xFFa1a1aa);
  static const Color zinc100 = Color(0xFFf4f4f5);
  static const Color emerald500 = Color(0xFF10b981);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();

    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  Future<void> _toggleBiometricLogin(
    bool enabled,
    AuthViewModel authViewModel,
  ) async {
    await authViewModel.setBiometricLoginEnabled(enabled);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          enabled ? 'Biometric login enabled' : 'Biometric login disabled',
        ),
        backgroundColor: enabled ? emerald500 : Colors.orangeAccent,
      ),
    );
  }

  Future<void> _handleLogout(AuthViewModel authViewModel) async {
    final shouldLogout =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: zinc900,
            title: const Text('Logout', style: TextStyle(color: zinc100)),
            content: const Text(
              'Are you sure you want to logout?',
              style: TextStyle(color: zinc400),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel', style: TextStyle(color: zinc400)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Logout', style: TextStyle(color: zinc100)),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldLogout) return;

    authViewModel.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/login');
  }

  Future<void> _handleDeleteAccount(
    AuthViewModel authViewModel,
    TodoViewModel todoViewModel,
  ) async {
    final shouldDelete =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: zinc900,
            title: const Text(
              'Delete Account',
              style: TextStyle(color: zinc100),
            ),
            content: const Text(
              'This will remove your account data and all tasks. Continue?',
              style: TextStyle(color: zinc400),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel', style: TextStyle(color: zinc400)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldDelete) return;

    await todoViewModel.deleteAllTodos();
    await authViewModel.deleteAccount();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/login');
  }

  void _showAccountActionsSheet(
    AuthViewModel authViewModel,
    TodoViewModel todoViewModel,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          decoration: _outlinedPanel(radius: 16, color: zinc950),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: zinc700,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Account',
                style: TextStyle(
                  color: zinc100,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.logout_rounded, color: zinc100),
                title: const Text('Logout', style: TextStyle(color: zinc100)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _handleLogout(authViewModel);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text(
                  'Delete account',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _handleDeleteAccount(authViewModel, todoViewModel);
                },
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _outlinedPanel({double radius = 10, Color? color}) {
    return BoxDecoration(
      color: color ?? zinc900,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: zinc800),
    );
  }

  InputDecoration _sheetFieldStyle(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: zinc400, fontSize: 14),
      prefixIcon: Icon(icon, color: zinc400, size: 20),
      filled: true,
      fillColor: zinc900,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: zinc800),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: zinc400),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final todoViewModel = Provider.of<TodoViewModel>(context);
    final authViewModel = Provider.of<AuthViewModel>(context);

    List<TodoModel> filteredTodos = todoViewModel.todos.where((todo) {
      final matchesSearch = todo.title.toLowerCase().contains(_searchQuery);
      final matchesCompletion = _showCompleted || !todo.isCompleted;
      return matchesSearch && matchesCompletion;
    }).toList();

    filteredTodos.sort((a, b) {
      switch (_sortBy) {
        case 'title':
          return a.title.compareTo(b.title);
        case 'completed':
          if (a.isCompleted == b.isCompleted) return 0;
          return a.isCompleted ? 1 : -1;
        case 'created':
        default:
          return b.createdAt.compareTo(a.createdAt);
      }
    });

    final completedCount = todoViewModel.todos
        .where((t) => t.isCompleted)
        .length;
    final totalCount = todoViewModel.todos.length;
    final completion = totalCount == 0 ? 0.0 : completedCount / totalCount;

    return Scaffold(
      backgroundColor: zinc950,
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        title: Text(
          'CipherTask',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: zinc100,
            letterSpacing: -0.3,
          ),
        ),
        backgroundColor: zinc950,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: zinc800),
        ),
        actions: [
          if (todoViewModel.todos.any((t) => t.isCompleted))
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: _outlinedPanel(),
              child: IconButton(
                icon: const Icon(Icons.clear_all, color: Colors.orangeAccent),
                tooltip: 'Clear completed',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: zinc900,
                      title: const Text(
                        'Clear Completed Tasks',
                        style: TextStyle(color: zinc100),
                      ),
                      content: const Text(
                        'Remove all completed tasks?',
                        style: TextStyle(color: zinc400),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: zinc400),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final completedTasks = todoViewModel.todos
                                .where((t) => t.isCompleted)
                                .toList();
                            for (final task in completedTasks) {
                              await todoViewModel.deleteTodo(task.id!);
                            }
                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                          },
                          child: const Text(
                            'Clear',
                            style: TextStyle(color: Colors.orangeAccent),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: _outlinedPanel(),
            child: IconButton(
              icon: Icon(
                authViewModel.isBiometricLoginEnabled
                    ? Icons.fingerprint_rounded
                    : Icons.fingerprint_outlined,
                color: authViewModel.isBiometricLoginEnabled
                    ? emerald500
                    : zinc400,
              ),
              tooltip: authViewModel.isBiometricLoginEnabled
                  ? 'Disable biometric login'
                  : 'Enable biometric login',
              onPressed: () {
                _toggleBiometricLogin(
                  !authViewModel.isBiometricLoginEnabled,
                  authViewModel,
                );
              },
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: _outlinedPanel(),
            child: IconButton(
              icon: const Icon(Icons.menu_rounded, color: zinc100),
              tooltip: 'Account options',
              onPressed: () =>
                  _showAccountActionsSheet(authViewModel, todoViewModel),
            ),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: zinc950,
          child: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 18),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: zinc900,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: zinc800),
                    ),
                    child: const Icon(
                      Icons.terminal_rounded,
                      size: 28,
                      color: zinc100,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Secure task workspace',
                    style: GoogleFonts.inter(
                      color: zinc100,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage encrypted notes and task progress',
                    style: TextStyle(
                      fontSize: 13,
                      color: zinc400.withValues(alpha: 0.95),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: _outlinedPanel(),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: zinc100),
                      decoration: InputDecoration(
                        hintText: 'Search tasks...',
                        hintStyle: const TextStyle(color: zinc400),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: zinc400,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: zinc400),
                                onPressed: () {
                                  _searchController.clear();
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: _outlinedPanel(),
                            child: DropdownButton<String>(
                              value: _sortBy,
                              dropdownColor: zinc900,
                              style: const TextStyle(color: zinc100),
                              underline: const SizedBox(),
                              isExpanded: true,
                              iconEnabledColor: zinc400,
                              items: const [
                                DropdownMenuItem(
                                  value: 'created',
                                  child: Text('Sort by Date'),
                                ),
                                DropdownMenuItem(
                                  value: 'title',
                                  child: Text('Sort by Title'),
                                ),
                                DropdownMenuItem(
                                  value: 'completed',
                                  child: Text('Sort by Status'),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _sortBy = value!;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          decoration: _outlinedPanel(
                            color: _showCompleted ? zinc800 : zinc900,
                          ),
                          child: IconButton(
                            icon: Icon(
                              _showCompleted
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: _showCompleted ? zinc100 : zinc400,
                            ),
                            tooltip: _showCompleted
                                ? 'Hide completed'
                                : 'Show completed',
                            onPressed: () {
                              setState(() {
                                _showCompleted = !_showCompleted;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (totalCount > 0)
                    Container(
                      margin: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: completion,
                              minHeight: 6,
                              backgroundColor: zinc800,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                emerald500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${(completion * 100).round()}% Complete',
                            style: const TextStyle(
                              color: zinc400,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Showing: ${filteredTodos.length} of ${todoViewModel.todos.length}',
                          style: const TextStyle(color: zinc400, fontSize: 12),
                        ),
                        Text(
                          'Completed: $completedCount',
                          style: const TextStyle(color: zinc100, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: filteredTodos.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _searchQuery.isNotEmpty
                                      ? Icons.search_off
                                      : Icons.task_alt_rounded,
                                  size: 60,
                                  color: zinc700,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _searchQuery.isNotEmpty
                                      ? 'No tasks match your search'
                                      : 'No secure tasks yet',
                                  style: const TextStyle(
                                    color: zinc100,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _searchQuery.isNotEmpty
                                      ? 'Try a different search term'
                                      : 'Tap + to add your first task',
                                  style: const TextStyle(
                                    color: zinc400,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: filteredTodos.length,
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 16,
                            ),
                            itemBuilder: (context, index) {
                              final todo = filteredTodos[index];
                              return Dismissible(
                                key: Key(todo.id.toString()),
                                direction: DismissDirection.horizontal,
                                background: Container(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: emerald500.withValues(alpha: 0.22),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  alignment: Alignment.centerLeft,
                                  padding: const EdgeInsets.only(left: 20),
                                  child: const Icon(
                                    Icons.check_circle,
                                    color: emerald500,
                                    size: 28,
                                  ),
                                ),
                                secondaryBackground: Container(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  child: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                    size: 28,
                                  ),
                                ),
                                confirmDismiss: (direction) async {
                                  if (direction ==
                                      DismissDirection.startToEnd) {
                                    await todoViewModel.toggleTodoStatus(todo);
                                    return false;
                                  }

                                  final shouldDelete =
                                      await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text(
                                            'Delete Task?',
                                            style: TextStyle(color: zinc100),
                                          ),
                                          backgroundColor: zinc900,
                                          content: const Text(
                                            'This action cannot be undone',
                                            style: TextStyle(color: zinc400),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: const Text(
                                                'Cancel',
                                                style: TextStyle(
                                                  color: zinc400,
                                                ),
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              child: const Text(
                                                'Delete',
                                                style: TextStyle(
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ) ??
                                      false;

                                  if (shouldDelete) {
                                    await todoViewModel.deleteTodo(todo.id!);
                                  }
                                  return false;
                                },
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 6,
                                  ),
                                  decoration: _outlinedPanel(
                                    radius: 12,
                                    color: zinc900,
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 4,
                                    ),
                                    leading: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: todo.isCompleted
                                            ? zinc800
                                            : emerald500.withValues(alpha: 0.2),
                                      ),
                                      child: Icon(
                                        todo.isCompleted
                                            ? Icons.check_circle
                                            : Icons.task_alt,
                                        color: todo.isCompleted
                                            ? zinc100
                                            : emerald500,
                                        size: 24,
                                      ),
                                    ),
                                    title: Text(
                                      todo.title,
                                      style:
                                          const TextStyle(
                                            color: zinc100,
                                            fontWeight: FontWeight.w500,
                                          ).copyWith(
                                            decoration: todo.isCompleted
                                                ? TextDecoration.lineThrough
                                                : null,
                                          ),
                                    ),
                                    subtitle: Text(
                                      'Tap to view secret note • Swipe to complete/delete',
                                      style: TextStyle(
                                        color: zinc400.withValues(alpha: 0.95),
                                        fontSize: 12,
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            Icons.edit,
                                            color: zinc400,
                                            size: 20,
                                          ),
                                          tooltip: 'Edit task',
                                          onPressed: () => _showAddTaskDialog(
                                            context,
                                            todoViewModel,
                                            todo: todo,
                                          ),
                                        ),
                                        Checkbox(
                                          value: todo.isCompleted,
                                          side: const BorderSide(
                                            color: zinc700,
                                          ),
                                          activeColor: zinc100,
                                          checkColor: zinc950,
                                          onChanged: (val) {
                                            todoViewModel.toggleTodoStatus(
                                              todo,
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                    onTap: () => _showSecretNote(
                                      context,
                                      todo,
                                      todoViewModel,
                                    ),
                                    onLongPress: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text(
                                            'Delete Task?',
                                            style: TextStyle(color: zinc100),
                                          ),
                                          backgroundColor: zinc900,
                                          content: const Text(
                                            'This action cannot be undone',
                                            style: TextStyle(color: zinc400),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: const Text(
                                                'Cancel',
                                                style: TextStyle(
                                                  color: zinc400,
                                                ),
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: () async {
                                                await todoViewModel.deleteTodo(
                                                  todo.id!,
                                                );
                                                if (context.mounted) {
                                                  Navigator.pop(context);
                                                }
                                              },
                                              child: const Text(
                                                'Delete',
                                                style: TextStyle(
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: zinc800),
        ),
        child: FloatingActionButton(
          onPressed: () => _showAddTaskDialog(context, todoViewModel),
          backgroundColor: zinc100,
          foregroundColor: zinc950,
          elevation: 0,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  void _showSecretNote(BuildContext context, TodoModel todo, TodoViewModel vm) {
    final decryptedNote = vm.decryptSecretNote(todo.encryptedSecretNotes);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: zinc900,
        title: Text(
          'Secret Note: ${todo.title}',
          style: const TextStyle(color: zinc100),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'DECRYPTED DATA:',
              style: const TextStyle(fontSize: 10, color: zinc400),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: zinc950,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: zinc800),
              ),
              child: Text(
                decryptedNote.isEmpty ? 'No secret note' : decryptedNote,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: decryptedNote.isEmpty ? zinc400 : zinc100,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: zinc100)),
          ),
        ],
      ),
    );
  }

  void _showAddTaskDialog(
    BuildContext context,
    TodoViewModel vm, {
    TodoModel? todo,
  }) {
    final titleController = TextEditingController(text: todo?.title ?? '');
    final noteController = TextEditingController(
      text: todo != null ? vm.decryptSecretNote(todo.encryptedSecretNotes) : '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom:
              MediaQuery.of(context).viewInsets.bottom +
              MediaQuery.of(context).padding.bottom,
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: zinc950,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: zinc800),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: zinc700,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  todo == null ? 'New Secure Task' : 'Edit Secure Task',
                  style: const TextStyle(
                    color: zinc100,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: zinc100),
                  decoration: _sheetFieldStyle('Title', Icons.title).copyWith(
                    hintText: 'Enter task title',
                    hintStyle: const TextStyle(color: zinc400),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: noteController,
                  style: const TextStyle(color: zinc100),
                  maxLines: 3,
                  decoration:
                      _sheetFieldStyle(
                        'Secret Note (AES-256)',
                        Icons.security,
                      ).copyWith(
                        hintText: 'Enter your encrypted note',
                        hintStyle: const TextStyle(color: zinc400),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(bottom: 48),
                          child: const Icon(Icons.security, color: zinc400),
                        ),
                      ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (titleController.text.isNotEmpty) {
                        if (todo == null) {
                          await vm.addTodo(
                            titleController.text,
                            noteController.text,
                          );
                        } else {
                          await vm.updateTodo(
                            todo.id!,
                            titleController.text,
                            noteController.text,
                          );
                        }
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: zinc100,
                      foregroundColor: zinc950,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      todo == null ? 'Secure Save' : 'Update Securely',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
