import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'workspace_store.dart';

class WorkspaceScreen extends StatefulWidget {
  const WorkspaceScreen({super.key});
  @override
  State<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends State<WorkspaceScreen> {
  int tab = 0;
  String query = '';
  bool lowOnly = false;
  String? branch;
  void message(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.toString().replaceFirst('Bad state: ', ''))),
    );
  }

  Future<void> edit([StockItem? item]) async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => ItemEditor(item: item)));
  }

  Future<void> forecast(StockItem item) async {
    try {
      await context.read<WorkspaceStore>().forecast(item);
    } catch (error) {
      message(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WorkspaceStore>();
    if (store.loadError != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(store.loadError!),
          ),
        ),
      );
    }
    if (!store.ready) return const SettingsScreen(onboarding: true);
    final all = store.items;
    final selectedBranch = store.branches.contains(branch) ? branch : null;
    final filtered = all
        .where(
          (item) =>
              (selectedBranch == null || item.branch == selectedBranch) &&
              (!lowOnly || item.stock <= item.reorder) &&
              '${item.name} ${item.branch} ${item.values['category']}'
                  .toLowerCase()
                  .contains(query.toLowerCase()),
        )
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('GOODIE AI'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (value) => setState(() => tab = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.grid_view_rounded),
            label: 'Overview',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            label: 'Inventory',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_rounded),
            label: 'Forecasts',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: store.busyId == null ? () => edit() : null,
        icon: const Icon(Icons.add),
        label: const Text('Add product'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
            children: [
              Text(
                tab == 0
                    ? store.business
                    : tab == 1
                    ? 'Inventory'
                    : 'Demand forecasts',
                style: Theme.of(context).textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                tab == 0
                    ? '${all.length} products · ${store.branches.length} branches'
                    : tab == 1
                    ? 'Stock across your branches'
                    : 'Plan your next stock order',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              if (tab == 0) ...[
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    metric(
                      'Units on hand',
                      '${store.units}',
                      Icons.inventory_2_outlined,
                    ),
                    metric(
                      'Low-stock products',
                      '${store.lowStock}',
                      Icons.warning_amber_rounded,
                    ),
                    metric(
                      'Stock cost',
                      NumberFormat.currency(
                        locale: 'en_IN',
                        symbol: '₹',
                        decimalDigits: 0,
                      ).format(store.stockValue),
                      Icons.account_balance_wallet_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Needs attention',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() {
                        tab = 1;
                        lowOnly = true;
                      }),
                      child: const Text('View inventory'),
                    ),
                  ],
                ),
                if (all.isEmpty)
                  empty(
                    'Your inventory starts here',
                    'Add your first product to track stock.',
                    Icons.storefront_outlined,
                  )
                else if (store.lowStock == 0)
                  empty(
                    'Stock levels look good',
                    'No products below their reorder point.',
                    Icons.check_circle_outline,
                  )
                else
                  ...all
                      .where((item) => item.stock <= item.reorder)
                      .map((item) => tile(item, store)),
              ] else ...[
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search products or branches',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) => setState(() => query = value),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('All branches'),
                      selected: selectedBranch == null,
                      onSelected: (_) => setState(() => branch = null),
                    ),
                    ...store.branches.map(
                      (name) => ChoiceChip(
                        label: Text(name),
                        selected: selectedBranch == name,
                        onSelected: (_) => setState(() => branch = name),
                      ),
                    ),
                    FilterChip(
                      label: const Text('Low stock'),
                      selected: lowOnly,
                      onSelected: (value) => setState(() => lowOnly = value),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (filtered.isEmpty)
                  empty(
                    all.isEmpty ? 'No products yet' : 'No matches',
                    all.isEmpty
                        ? 'Add a product to get started.'
                        : 'Try another search or filter.',
                    Icons.inventory_2_outlined,
                  )
                else
                  ...filtered.map(
                    (item) => tile(item, store, showForecast: tab == 2),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget metric(String label, String value, IconData icon) => SizedBox(
    width: 225,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon),
            const SizedBox(height: 16),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(label),
          ],
        ),
      ),
    ),
  );
  Widget empty(String title, String subtitle, IconData icon) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 36),
    child: Column(
      children: [
        Icon(icon, size: 40),
        const SizedBox(height: 16),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(subtitle, textAlign: TextAlign.center),
      ],
    ),
  );
  Widget tile(
    StockItem item,
    WorkspaceStore store, {
    bool showForecast = false,
  }) {
    final result = item.forecast;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text('${item.branch} · ${item.values['category']}'),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Edit product',
                    onPressed: store.busyId == null ? () => edit(item) : null,
                    icon: const Icon(Icons.edit_outlined),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 24,
                runSpacing: 10,
                children: [
                  Text('${item.stock} units on hand'),
                  Text('Reorder at ${item.reorder}'),
                  if (item.stock <= item.reorder)
                    const Text(
                      'Low stock',
                      style: TextStyle(color: Colors.orangeAccent),
                    ),
                ],
              ),
              if (showForecast) ...[
                const Divider(height: 30),
                Text(
                  'Forecast date: ${DateFormat.yMMMd().format(DateTime.parse(item.values['date'] as String))}',
                ),
                const SizedBox(height: 10),
                if (result == null)
                  const Text('No forecast yet')
                else ...[
                  Wrap(
                    spacing: 24,
                    runSpacing: 10,
                    children: [
                      Text('Demand: ${result['expected_demand']} units'),
                      Text(
                        'Suggested order: ${result['restock_quantity']} units',
                      ),
                      Text(
                        'Target stock: ${result['recommended_inventory']} units',
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Updated ${DateFormat.yMMMd().add_jm().format(DateTime.parse(result['generated_at'] as String))}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: store.busyId == null ? () => forecast(item) : null,
                  icon: store.busyId == item.id
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_graph),
                  label: Text(
                    result == null ? 'Generate forecast' : 'Refresh forecast',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, this.onboarding = false});
  final bool onboarding;
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final form = GlobalKey<FormState>();
  late TextEditingController name;
  late TextEditingController endpoint;
  bool saving = false;
  @override
  void initState() {
    super.initState();
    final store = context.read<WorkspaceStore>();
    name = TextEditingController(text: store.business);
    endpoint = TextEditingController(text: store.endpoint);
  }

  @override
  void dispose() {
    name.dispose();
    endpoint.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    setState(() => saving = true);
    try {
      await context.read<WorkspaceStore>().configure(name.text, endpoint.text);
      if (mounted && !widget.onboarding) Navigator.pop(context);
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save changes. Try again.')),
        );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.onboarding ? 'Welcome to GOODIE AI' : 'Settings'),
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: Form(
          key: form,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                widget.onboarding
                    ? 'Set up your business'
                    : 'Business workspace',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Business name'),
                maxLength: 80,
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Enter your business name'
                    : null,
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: endpoint,
                decoration: const InputDecoration(
                  labelText: 'Forecast service URL (optional)',
                ),
                keyboardType: TextInputType.url,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final uri = Uri.tryParse(v.trim());
                  return uri == null ||
                          !['https', 'http'].contains(uri.scheme) ||
                          uri.host.isEmpty ||
                          uri.userInfo.isNotEmpty ||
                          uri.hasQuery ||
                          uri.hasFragment
                      ? 'Enter a valid service URL'
                      : null;
                },
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: saving ? null : save,
                child: Text(
                  saving
                      ? 'Saving…'
                      : widget.onboarding
                      ? 'Create workspace'
                      : 'Save changes',
                ),
              ),
              const SizedBox(height: 32),
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.phone_android_outlined),
                title: Text('Storage'),
                subtitle: Text('On this device'),
              ),
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.info_outline),
                title: Text('GOODIE AI'),
                subtitle: Text('1.0.0'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class ItemEditor extends StatefulWidget {
  const ItemEditor({super.key, this.item});
  final StockItem? item;
  @override
  State<ItemEditor> createState() => _ItemEditorState();
}

class _ItemEditorState extends State<ItemEditor> {
  final form = GlobalKey<FormState>();
  final fields = <String, TextEditingController>{};
  bool saving = false;
  static const labels = {
    'product': 'Product name',
    'store': 'Branch name',
    'category': 'Category',
    'store_type': 'Store type',
    'inventory': 'Units on hand',
    'reorder_point': 'Reorder point',
    'price': 'Selling price (₹)',
    'cost_price': 'Unit cost (₹)',
    'competitor_price': 'Competitor price (₹)',
    'discount': 'Discount (%)',
    'previous_week_sales': 'Previous week sales (units)',
    'previous_month_sales': 'Previous month sales (units)',
    'temperature': 'Temperature (°C)',
    'rainfall_mm': 'Rainfall (mm)',
    'season': 'Season',
    'promotion': 'Promotion',
    'holiday': 'Holiday',
  };
  static const integers = {
    'inventory',
    'reorder_point',
    'previous_week_sales',
    'previous_month_sales',
  };
  static const numbers = {
    'inventory',
    'reorder_point',
    'price',
    'cost_price',
    'competitor_price',
    'discount',
    'previous_week_sales',
    'previous_month_sales',
    'temperature',
    'rainfall_mm',
  };
  DateTime date = DateTime.now();
  @override
  void initState() {
    super.initState();
    for (final key in labels.keys) {
      fields[key] = TextEditingController(
        text: widget.item?.values[key]?.toString() ?? '',
      );
    }
    if (widget.item != null)
      date = DateTime.parse(widget.item!.values['date'] as String);
  }

  @override
  void dispose() {
    for (final field in fields.values) {
      field.dispose();
    }
    super.dispose();
  }

  String? validate(String key, String? value) {
    if (value == null || value.trim().isEmpty) {
      return {
            'product',
            'store',
            'category',
            'inventory',
            'reorder_point',
            'price',
            'cost_price',
          }.contains(key)
          ? 'Required'
          : null;
    }
    if (numbers.contains(key)) {
      final n = num.tryParse(value);
      if (n == null || !n.isFinite || (key != 'temperature' && n < 0))
        return 'Enter a valid ${key == 'temperature' ? '' : 'non-negative '}number';
      if (integers.contains(key) && n != n.roundToDouble())
        return 'Enter whole units';
      if (key == 'discount' && n > 100) return 'Use 0–100';
      if (key == 'temperature' && (n < -60 || n > 60)) return 'Use -60 to 60';
    }
    return null;
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    setState(() => saving = true);
    final values = <String, dynamic>{
      'date': DateFormat('yyyy-MM-dd').format(date),
    };
    for (final key in fields.keys) {
      final text = fields[key]!.text.trim();
      if (text.isEmpty) continue;
      values[key] = integers.contains(key)
          ? num.parse(text).toInt()
          : numbers.contains(key)
          ? double.parse(text)
          : text;
    }
    try {
      await context.read<WorkspaceStore>().saveItem(
        StockItem(
          id:
              widget.item?.id ??
              DateTime.now().microsecondsSinceEpoch.toString(),
          values: values,
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save this product. Try again.'),
          ),
        );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> remove() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete product?'),
        content: Text(
          'Remove ${widget.item!.name} from ${widget.item!.branch}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await context.read<WorkspaceStore>().deleteItem(widget.item!.id);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not delete this product.')),
        );
    }
  }

  Widget field(String key) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      controller: fields[key],
      decoration: InputDecoration(labelText: labels[key]),
      keyboardType: numbers.contains(key)
          ? const TextInputType.numberWithOptions(decimal: true, signed: true)
          : TextInputType.text,
      validator: (v) => validate(key, v),
    ),
  );
  Widget choice(String key, List<String> options) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: DropdownButtonFormField<String>(
      value: options.contains(fields[key]!.text) ? fields[key]!.text : null,
      decoration: InputDecoration(labelText: labels[key]),
      items: options
          .map((v) => DropdownMenuItem(value: v, child: Text(v)))
          .toList(),
      onChanged: (v) => fields[key]!.text = v ?? '',
      validator: (v) => validate(key, v),
    ),
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.item == null ? 'Add product' : 'Edit product'),
      actions: [
        if (widget.item != null)
          IconButton(
            tooltip: 'Delete product',
            onPressed: saving ? null : remove,
            icon: const Icon(Icons.delete_outline),
          ),
      ],
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 650),
        child: Form(
          key: form,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Product details',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 18),
              ...[
                'product',
                'store',
                'category',
                'inventory',
                'reorder_point',
                'price',
                'cost_price',
              ].map(field),
              const SizedBox(height: 14),
              ExpansionTile(
                title: const Text('Forecast inputs'),
                tilePadding: EdgeInsets.zero,
                maintainState: true,
                children: [
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Forecast date'),
                    subtitle: Text(DateFormat.yMMMd().format(date)),
                    trailing: const Icon(Icons.calendar_month),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: date,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setState(() => date = picked);
                    },
                  ),
                  const SizedBox(height: 12),
                  ...[
                    'store_type',
                    'previous_week_sales',
                    'previous_month_sales',
                    'competitor_price',
                    'discount',
                    'temperature',
                    'rainfall_mm',
                    'season',
                  ].map(field),
                  choice('promotion', ['None', 'Low', 'Medium', 'High']),
                  choice('holiday', ['No', 'Yes']),
                ],
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: saving ? null : save,
                child: Text(saving ? 'Saving…' : 'Save product'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
