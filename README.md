# To-Do List App

A feature-rich To-Do List application built with Flutter. This app helps you organize your tasks efficiently with category filters, notifications, and a clean, user-friendly interface.

## Features

- Add, edit, and delete tasks with ease.
- Filter tasks by categories: All, Work, Personal, Wishlist.
- Mark tasks as done or starred for prioritization.
- Set deadlines and reminders with local notifications.
- Undo task deletion with a convenient Snackbar action.
- Detailed task view with notes and repeat rules.
- Supports Indonesian locale for date formatting.
- Responsive UI with Material Design and custom theming.

## Installation and Setup

1. Ensure you have Flutter installed. For installation instructions, visit [Flutter official site](https://flutter.dev/docs/get-started/install).

2. Clone this repository:
   ```
   git clone https://github.com/AhmadDiksa/ToDoList-App
   ```

3. Navigate to the project directory:
   ```
   cd to_do_list_app
   ```

4. Get the dependencies:
   ```
   flutter pub get
   ```

5. Run the app on your preferred device or emulator:
   ```
   flutter run
   ```

## Usage

- Use the bottom navigation bar to navigate through different sections (currently Home is implemented).
- Use the filter chips at the top to filter tasks by category.
- Tap the "+" floating action button to add a new task.
- Swipe tasks to reveal options like delete, star, or set details.
- Tap a task to view and edit its details.
- Use the calendar screen to view tasks by date.
- Check notifications for reminders and deadlines.

## Technologies Used

- Flutter & Dart
- Provider for state management
- SQLite for local data persistence (via DatabaseHelper)
- Local notifications for reminders and deadlines
- intl package for locale-specific date formatting

## Contributing

Contributions are welcome! To contribute:

1. Fork the repository.
2. Create a new branch for your feature or bugfix.
3. Make your changes and commit them with clear messages.
4. Push your branch to your fork.
5. Open a pull request describing your changes.

Please ensure your code follows the existing style and includes relevant tests.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

---

This app is designed to help you stay organized and productive. Feel free to contribute or suggest improvements!
