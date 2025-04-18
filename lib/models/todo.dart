class Todo {
  final int? id;
  final String date;
  final String text;
  final bool completed;

  Todo(
      {this.id,
      required this.date,
      required this.text,
      this.completed = false});

  bool get isDone => completed == 1;

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date,
        'text': text,
        'completed': completed ? 1 : 0,
      };

  factory Todo.fromMap(Map<String, dynamic> map) => Todo(
        id: map['id'],
        date: map['date'],
        text: map['text'],
        completed: map['completed'] == 1,
      );
}
