import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:task_tracker_restapi/screens/add_page.dart';
import 'package:http/http.dart' as http;
// ignore: depend_on_referenced_packages
import 'package:fl_chart/fl_chart.dart';
// ignore: library_prefixes
import 'package:pdf/widgets.dart' as pdfWid;
// import 'package:task_tracker_restapi/screens/pdf_view.dart';
import 'package:task_tracker_restapi/screens/settime.dart';

class TodoListPage extends StatefulWidget {
  const TodoListPage({super.key});

  @override
  State<TodoListPage> createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage> {
  final PageController _pageController = PageController(initialPage: 5000);
  DateTime selectedDate = DateTime.now();
  bool isLoading = true;
  List items = [];
  Color selectedColor = Colors.black;
  Color selectedColor2 = Colors.white12;
  @override
  void initState() {
    super.initState();
    fetchTodo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task List'),
        //shadowColor: Color.fromARGB(223, 63, 14, 14),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    // Display the selected date on the top of the screen
                    formatDate(selectedDate),
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                // Show the bar chart above the task list
                Container(
                  height: 200,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TaskCompletionBarChart(
                    items: items,
                    selectedDate: selectedDate,
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    //reverse: true,
                    //initialPage: DateTime.now().day - 1, // Set the current date index as the initial page.
                    onPageChanged: (index) {
                      const CircularProgressIndicator();
                      // Swiping is detected. Update the selected date accordingly.
                      setState(() {
                        selectedDate =
                            DateTime.now().add(Duration(days: index - 5000));
                      });
                      fetchTodo();
                    },
                    itemBuilder: (context, index) {
                      return RefreshIndicator(
                        onRefresh: fetchTodo,
                        child: ListView.builder(
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index] as Map;
                            final id = item['_id'] as String;
                            final taskDate = selectedDate;
                            final isCompleted = item['is_completed'] as bool;
                            if (taskDate.year == selectedDate.year &&
                                taskDate.month == selectedDate.month &&
                                taskDate.day == selectedDate.day) {
                              return GestureDetector(
                                onTap: () {
                                  showDialog(
                                      context: context,
                                      builder: (context) {
                                        return SimpleDialog(
                                          title: const Text(
                                            'Pick Color',
                                            style: TextStyle(
                                                fontSize: 25,
                                                fontWeight: FontWeight.bold),
                                          ),
                                          children: [
                                            ColorPicker(
                                                pickerColor: selectedColor2,
                                                onColorChanged: (color) {
                                                  selectedColor2 = color;
                                                  setState(() {});
                                                })
                                          ],
                                        );
                                      });
                                },
                                child: Container(
                                  // decoration: const BoxDecoration(
                                  //   border: Border(bottom: BorderSide()),
                                  //   //color: selectedColor2,
                                  // ),
                                  color: selectedColor2,
                                  child: ListTile(
                                    leading: Checkbox(
                                      value: isCompleted,
                                      onChanged: (_) => toggleCompletionStatus(
                                          id, !isCompleted),
                                    ),
                                    title: Text(
                                      item['title'],
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        decoration: isCompleted
                                            ? TextDecoration.lineThrough
                                            : TextDecoration.none,
                                      ),
                                    ),
                                    subtitle: GestureDetector(
                                      onTap: () {
                                        showDialog(
                                            context: context,
                                            builder: (context) {
                                              return SimpleDialog(
                                                title: const Text(
                                                  'Pick Color',
                                                  style: TextStyle(
                                                      fontSize: 25,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                                children: [
                                                  ColorPicker(
                                                      pickerColor:
                                                          selectedColor,
                                                      onColorChanged: (color) {
                                                        selectedColor = color;
                                                        setState(() {});
                                                      })
                                                ],
                                              );
                                            });
                                      },
                                      child: Text(
                                        item['description'],
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color:
                                              selectedColor, // Use the selected color here
                                        ),
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            //NotificationService().showNotification();
                                            Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        const SetTime(
                                                          title: 'Title',
                                                        )));
                                          },
                                          child: const Text(
                                              'p'), // Replace 'Icons.info' with your desired icon.
                                        ),
                                        PopupMenuButton(
                                          onSelected: (value) async {
                                            if (value == 'edit') {
                                              naigateToEditPage(item);
                                            } else if (value == 'delete') {
                                              deleteById(id);
                                            } else if (value == 'pdf') {
                                              Uint8List pdfBytes = await _createPdf();
                                                _showPDFDialog(pdfBytes);
                                            }
                                          },
                                          itemBuilder: (context) {
                                            return [
                                              const PopupMenuItem(
                                                value: 'pdf',
                                                child: Text('PDF'),
                                              ),
                                              const PopupMenuItem(
                                                value: 'edit',
                                                child: Text('Edit'),
                                              ),
                                              const PopupMenuItem(
                                                value: 'delete',
                                                child: Text('Delete'),
                                              ),
                                            ];
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            } else {
                              return Container();
                            }
                          },
                        ),
                      );
                    },
                    //child: const Center(child: CircularProgressIndicator()),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: naigatetoAddPage,
        label: const Text('Add Task'),
      ),
    );
  }

  void _showPDFDialog(Uint8List pdfBytes) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Generated PDF"),
              const SizedBox(height: 16.0),
              SizedBox(
                width: 500, // Specify a width
                height: 500, // Specify a height
                child: PdfPreview(
                  build: (format) => pdfBytes,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}




  Future<Uint8List> _createPdf() async{
  final pdf = pdfWid.Document(
    version: PdfVersion.pdf_1_4,
    compress: true,
  );
  pdf.addPage(
    pdfWid.Page(
      pageFormat: PdfPageFormat.standard,
      build: (context) {
        return pdfWid.Center(
          child: pdfWid.Column(
            mainAxisAlignment: pdfWid.MainAxisAlignment.center,
            children: [
              pdfWid.Text(
                "Generated PDF",
                style: pdfWid.TextStyle(
                  fontSize: 24,
                  fontWeight: pdfWid.FontWeight.bold,
                ),
              ),
              pdfWid.SizedBox(height: 20),
              pdfWid.Text(
                "Sanyam",
                style: pdfWid.TextStyle(
                  fontSize: 18,
                  fontWeight: pdfWid.FontWeight.bold,
                ),
              ),
              pdfWid.SizedBox(height: 10),
              pdfWid.Text(
                "pdf1",
                style: pdfWid.TextStyle(
                  fontSize: 18,
                  fontWeight: pdfWid.FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
  return pdf.save();
}


  Future<void> naigateToEditPage(Map item) async {
    final route = MaterialPageRoute(
        builder: (context) => AddTodoPage(
            todo: item, createdDate: DateTime.parse(item['created_at'])));
    await Navigator.push(context, route);
    setState(() {
      isLoading = true;
    });
    fetchTodo();
  }

  Future<void> naigatetoAddPage() async {
    final route = MaterialPageRoute(
        builder: (context) => AddTodoPage(createdDate: selectedDate));
    await Navigator.push(context, route);
    setState(() {
      isLoading = true;
    });
    fetchTodo();
  }

  Future<void> deleteById(String id) async {
    final url = 'https://api.nstack.in/v1/todos/$id';
    final uri = Uri.parse(url);
    final response = await http.delete(uri);
    if (response.statusCode == 200) {
      final filtered = items.where((element) => element['_id'] != id).toList();
      setState(() {
        items = filtered;
      });
    } else {
      showErrorMessage('Deletion Failed');
    }
  }

  Future<void> fetchTodo() async {
    const url = 'https://api.nstack.in/v1/todos?page=1&limit=10';
    final uri = Uri.parse(url);
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map;
      final result = json['items'] as List;
      final filteredItems = result.where((item) {
        final itemDate = DateTime.parse(
            item['created_at']); // Assuming the API provides the creation date.
        if (itemDate.year == selectedDate.year &&
            itemDate.month == selectedDate.month &&
            itemDate.day == selectedDate.day) {
          return true;
        } else {
          return false;
        }
        //itemDate.year == selectedDate.year &&
        //  itemDate.month == selectedDate.month &&
        //itemDate.day == selectedDate.day;
      }).toList();
      setState(() {
        items = filteredItems;
      });
    }
    setState(() {
      isLoading = false;
    });
  }

  // Future<void> fetchTodo() async {
  //   const url = 'https://api.nstack.in/v1/todos?page=1&limit=10';
  //   final uri = Uri.parse(url);
  //   final response = await http.get(uri);
  //   if (response.statusCode == 200) {
  //     final json = jsonDecode(response.body) as Map;
  //     final result = json['items'] as List;
  //     setState(() {
  //       items = result;
  //     });
  //   }
  //   setState(() {
  //     isLoading = false;
  //   });
  // }

  void showErrorMessage(String message) {
    final snackBar = SnackBar(
      content: Text(
        message,
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: Colors.red,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  String formatDate(DateTime date) {
    // Format the date to display in the header
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> toggleCompletionStatus(String id, bool isCompleted) async {
    final item = items.firstWhere((item) => item['_id'] == id);
    final body = {
      "title": item['title'],
      "description": item['description'],
      "is_completed": isCompleted,
    };
    final url =
        'https://api.nstack.in/v1/todos/$id'; // Use the task-specific endpoint
    final uri = Uri.parse(url);
    final response = await http.put(uri,
        body: jsonEncode(body), headers: {'Content-Type': 'application/json'});
    if (response.statusCode == 200) {
      setState(() {
        item['is_completed'] = isCompleted; // Update the local item status
      });
      log('Updation Success');
    } else {
      showErrorMessage('Updation Failed');
    }
  }

  // Future<void> toggleCompletionStatus(String id, bool isCompleted) async {
  //   final body = {
  //     "title": items.firstWhere((item) => item['_id'] == id)['title'],
  //     "description":
  //         items.firstWhere((item) => item['_id'] == id)['description'],
  //     "is_completed": isCompleted,
  //   };
  //   const url = 'https://api.nstack.in/v1/todos';
  //   final uri = Uri.parse(url);
  //   final response = await http.post(uri,
  //       body: jsonEncode(body), headers: {'Content-Type': 'application/json'});
  //   if (response.statusCode == 201) {
  //     // titleController.text = '';
  //     // descriptionController.text = '';
  //     deleteById(id);
  //     log('Updation Success');
  //     setState(() {
  //       isLoading = true;
  //     });
  //   } else {
  //     showErrorMessage('Updation Failed');
  //   }
  // }
}

class TaskCompletionBarChart extends StatelessWidget {
  final List items;
  final DateTime selectedDate;

  const TaskCompletionBarChart(
      {super.key, required this.items, required this.selectedDate});

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        barTouchData: BarTouchData(enabled: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: getBarGroups(),
      ),
    );
  }

  List<BarChartGroupData> getBarGroups() {
    final int totalTasks = items.length;
    final completedTasks =
        items.where((item) => item['is_completed'] == true).length;
    final incompleteTasks = totalTasks - completedTasks;

    final List<BarChartGroupData> barGroups = [];
    barGroups.add(makeBarChartGroupData(0, totalTasks.toDouble(), Colors.grey));
    barGroups
        .add(makeBarChartGroupData(1, completedTasks.toDouble(), Colors.green));
    barGroups
        .add(makeBarChartGroupData(2, incompleteTasks.toDouble(), Colors.red));
    return barGroups;
  }

  BarChartGroupData makeBarChartGroupData(int x, double y, Color barColor) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: barColor,
          width: 20,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(6),
            topRight: Radius.circular(6),
          ),
        ),
      ],
    );
  }
}
