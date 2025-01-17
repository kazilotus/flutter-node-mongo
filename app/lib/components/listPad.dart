import 'package:app/models/data/waitlists.dart';
import 'package:app/models/date.dart';
import 'package:app/models/services.dart';
import 'package:app/service/data/waitlists.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ListPad extends StatefulWidget {
  const ListPad({Key? key}) : super(key: key);

  @override
  State<ListPad> createState() => _ListPadState();
}

class _ListPadState extends State<ListPad> {
  // States for Add form
  String _name = "";
  String? _service = "";
  final TextEditingController _inputController = TextEditingController();

  // Sroll controller for the reorderlist view
  final ScrollController _scrollController = ScrollController();

  // Store ids of dismissed / removed cards
  List dismissedIds = <String>[];

  @override
  // Call server to fetch all data
  void initState() {
    super.initState();
    final waitlistData = Provider.of<WaitlistsData>(context, listen: false);
    waitlistData.getWaitlistsData();
  }

  @override
  Widget build(BuildContext context) {
    List<String> services = context.select<ServiceModel, List<String>>(
      (service) => service.getServices(),
    );

    return SafeArea(
      maintainBottomViewPadding: true,
      child: Container(
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 0),
        child: Scaffold(
          floatingActionButton: _addButton(context, services),
          body: _mainBody(),
        ),
      ),
    );
  }

  // Scroll down to the last item when cards exceed the container height
  void _scrollDown() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(seconds: 1),
      curve: Curves.fastOutSlowIn,
    );
  }

  // Update name field on state change in the add form
  void _updateInputData(String input) {
    setState(() {
      _name = input.trim();
    });
  }

  // Update service field on state change in the add form
  void _updateServiceSelection(String? selection) {
    setState(() {
      _service = selection?.trim();
    });
  }

  // Add a new item in the current waitlist
  void _addToList() async {
    var isServiceSelected = _service?.isNotEmpty;
    if (_name.isNotEmpty && isServiceSelected!) {
      final date = Provider.of<DateModel>(context, listen: false);
      final waitlistData = Provider.of<WaitlistsData>(context, listen: false);
      final Entry entry = Entry(
        idx: waitlistData.waitlistsModel!.newIndex(date.getFormatted()),
        name: _name,
        service: _service,
        completed: false,
      );
      waitlistData.insertWaitlistEntry(date.getFormatted(), entry);
      setState(() {
        _service = "";
        _inputController.text = "";
      });

      Navigator.pop(context);
      if (entry.idx > 0) {
        Future.delayed(const Duration(milliseconds: 300), () {
          _scrollDown();
        });
      }
    }
  }

  // Remove an item when swiped left from the current waitlist
  void _removeFromList(Entry entry) async {
    setState(() {
      dismissedIds.add(entry.id);
    });
    final date = Provider.of<DateModel>(context, listen: false);
    final waitlistData = Provider.of<WaitlistsData>(context, listen: false);
    waitlistData.removeWaitlistEntry(date.getFormatted(), entry);
  }

  void _toggleStatus(Entry entry, bool? status) async {
    final date = Provider.of<DateModel>(context, listen: false);
    final waitlistData = Provider.of<WaitlistsData>(context, listen: false);
    entry.setCompleted(status);
    waitlistData.updateWaitlistEntry(date.getFormatted(), entry);
  }

  // Reorder items in the waitlist
  void _onReorder(int oldIndex, int newIndex) {
    final date = Provider.of<DateModel>(context, listen: false).getFormatted();
    final waitlistData = Provider.of<WaitlistsData>(context, listen: false);
    WaitlistsDataModel wl = waitlistData.waitlistsModel!;
    wl.reorderWaitlist(date, oldIndex, newIndex);
    Waitlist orderedWaitlist =
        wl.waitlists.firstWhere((element) => element.date == date);
    waitlistData.reorderWaitlistEntry(date, orderedWaitlist);
  }

  // Open add form
  void _openInsertModal(BuildContext context, List<String> services) {
    const String title = 'Add to Waitlist';
    const String namePlaceHolderText = "Enter client's name";
    const String servicePlaceHolderText = 'Please select a service';

    const EdgeInsets buttonStyle = EdgeInsets.symmetric(
      horizontal: 30,
      vertical: 15,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 15,
            ),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.all(Radius.circular(10.0)),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 20,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    title,
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    alignment: Alignment.bottomCenter,
                    child: TextField(
                      autofocus: true,
                      controller: _inputController,
                      textInputAction: TextInputAction.next,
                      onChanged: _updateInputData,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(5)),
                          gapPadding: 4.0,
                        ),
                        hintText: namePlaceHolderText,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField(
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(5)),
                        gapPadding: 4.0,
                      ),
                      hintText: namePlaceHolderText,
                    ),
                    icon: const Icon(Icons.keyboard_arrow_down),
                    items: services.map((String items) {
                      return DropdownMenuItem(
                        value: items,
                        child: Text(items),
                      );
                    }).toList(),
                    onChanged: _updateServiceSelection,
                    isExpanded: true,
                    hint: const Text(servicePlaceHolderText),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            primary: Theme.of(context).primaryColorDark,
                            padding: buttonStyle,
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            primary: Theme.of(context).primaryColor,
                            padding: buttonStyle,
                          ),
                          onPressed: () => _addToList(),
                          child: const Text('Add'),
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Floating add action button
  Widget _addButton(BuildContext context, List<String> services) {
    return FloatingActionButton(
      onPressed: () => _openInsertModal(context, services),
      backgroundColor: Theme.of(context).primaryColor,
      child: const Icon(
        Icons.add,
        color: Colors.white,
      ),
    );
  }

  // Decorator for when a card is being dragged to a diiferent position
  Widget _proxyDecorator(Widget child, int index, Animation<double> animation) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
          ),
        ],
      ),
      child: child,
    );
  }

  // Main widget to render the waitilist
  Widget _mainBody() {
    final date = Provider.of<DateModel>(context).getFormatted();
    final waitlistData = Provider.of<WaitlistsData>(context);
    final waitlist = waitlistData.waitlistsModel?.waitlists.firstWhere(
      (waitlist) => waitlist.date == date,
      orElse: () => Waitlist(date: date, entries: []),
    );
    return Container(
      padding: const EdgeInsets.all(5),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        boxShadow: [
          const BoxShadow(
            color: Color.fromARGB(255, 27, 27, 27),
            offset: Offset(0, 0),
          ),
          BoxShadow(
            color: Theme.of(context).scaffoldBackgroundColor.withAlpha(150),
            spreadRadius: -3.0,
            blurRadius: 12.0,
          ),
        ],
      ),
      child:
          waitlistData.loading || waitlist == null || waitlist.entries.isEmpty
              ? Center(
                  child: Text(
                    (waitlistData.loading ? 'Loading' : "Waitlist Empty")
                        .toUpperCase(),
                    style: TextStyle(
                      color: Theme.of(context).secondaryHeaderColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : waitlistData.initialized
                  ? ReorderableListView(
                      key: Key(date),
                      scrollController: _scrollController,
                      buildDefaultDragHandles: false,
                      scrollDirection: Axis.vertical,
                      onReorder: _onReorder,
                      proxyDecorator: _proxyDecorator,
                      children: waitlist.entries
                          .where((e) => !dismissedIds.contains(e.id))
                          .map<Widget>((item) => _cardGenerator(item))
                          .toList(),
                    )
                  : null,
    );
  }

  // Single card widget for the waitlist
  Widget _cardGenerator(Entry item) {
    int idx = item.idx;
    return Dismissible(
      direction: DismissDirection.endToStart,
      key: Key("$idx"),
      onDismissed: (direction) => _removeFromList(item),
      background: Container(
        alignment: Alignment.centerRight,
        // color: Colors.grey.withOpacity(0.1),
        padding: const EdgeInsets.only(right: 20),
        child: Text(
          'SWIPE TO DELETE',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.red.withOpacity(0.4),
          ),
        ),
      ),
      child: Container(
        key: Key("$idx"),
        child: Card(
          elevation: 1,
          borderOnForeground: false,
          child: Container(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                ReorderableDragStartListener(
                  index: idx,
                  child: Icon(
                    Icons.drag_indicator,
                    color: Colors.red.withOpacity(0.5),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(left: 10),
                  child: Checkbox(
                    checkColor: Theme.of(context).cardColor,
                    activeColor: Colors.red.withOpacity(0.8),
                    value: item.completed,
                    onChanged: (bool? newValue) =>
                        _toggleStatus(item, newValue),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {},
                    child: Text("${item.name} • ${item.service}"),
                  ),
                ),
                Icon(
                  Icons.delete_sweep_outlined,
                  color: Colors.red.withOpacity(0.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
