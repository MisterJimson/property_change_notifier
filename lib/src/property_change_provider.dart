import 'package:flutter/widgets.dart';
import 'package:property_change_notifier/property_change_notifier.dart';

/// An [InheritedWidget] that provides access to a [PropertyChangeNotifier] to descendant widgets.
/// The type parameter [T] is the type of the [PropertyChangeNotifier] subclass.
///
/// A descendant widget can access the model instance by using the following syntax.
/// This will automatically register the widget to be rebuilt whenever any property changes on the model:
/// ```dart
/// final model = PropertyChangeProvider.of<MyModel>(context).value;
/// ```
///
/// To access the property name that was changed, use the following syntax:
/// ```dart
/// final property = PropertyChangeProvider.of<MyModel>(context).property;
/// ```
///
/// To register the widget to be rebuilt only on specific property changes, provide a [properties] parameter:
/// ```dart
/// final model = PropertyChangeProvider.of<MyModel>(context, properties: ['foo', 'bar']).value;
/// ```
///
/// To access the model without registering the widget to be rebuilt, provide a [listen] parameter with a value of false:
/// ```dart
/// final model = PropertyChangeProvider.of<MyModel>(context, listen: false).value;
/// ```
class PropertyChangeProvider<T extends PropertyChangeNotifier> extends StatefulWidget {
  /// Retrieves the [PropertyChangeModel] from the nearest ancestor [PropertyChangeProvider].
  /// If [listen] is true (which is the default), the calling widget will also be rebuilt
  /// whenever the ancestor's [PropertyChangeNotifier] model changes. To only rebuild
  /// for certain properties, provide them in the [properties] parameter.
  /// If [listen] is false, the [properties] parameter must be null or empty.
  static PropertyChangeModel<T> of<T extends PropertyChangeNotifier>(
    BuildContext context, {
    Iterable<Object> properties,
    bool listen = true,
  }) {
    assert(listen || properties == null, "Don't provide properties if you're not going to listen to them.");

    final typeOf = <T>() => T;

    final nullCheck = (InheritedModel model) {
      assert(model != null, 'Could not find an ancestor PropertyChangeProvider<$T>');
      return model;
    };

    if (!listen) {
      final type = typeOf<PropertyChangeModel<T>>();
      return nullCheck(context.ancestorWidgetOfExactType(type) as PropertyChangeModel);
    }

    if (properties == null || properties.isEmpty) {
      return nullCheck(InheritedModel.inheritFrom<PropertyChangeModel<T>>(context));
    }

    InheritedModel widget;
    for (final property in properties) {
      widget = InheritedModel.inheritFrom<PropertyChangeModel<T>>(context, aspect: property);
    }

    return nullCheck(widget);
  }

  /// Creates a [PropertyChangeProvider] that can be accessed by descendant widgets.
  PropertyChangeProvider({
    Key key,
    @required this.value,
    @required this.child,
  })  : assert(value != null),
        assert(child != null),
        super(key: key);

  /// The instance of [T] to provide to descendant widgets.
  final T value;

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.child}
  final Widget child;

  @override
  _PropertyChangeProviderState createState() => _PropertyChangeProviderState<T>();
}

/// The companion [State] object to [PropertyChangeProvider]. For private use only.
/// Subscribes as a global listener to the [PropertyChangeNotifier] instance at [widget].[value].
/// Rebuilds whenever a property is changed and creates a new [PropertyChangeModel] with a reference
/// to itself so it can access the original model instance and newly changed property name.
class _PropertyChangeProviderState<T extends PropertyChangeNotifier> extends State<PropertyChangeProvider<T>> {
  Object _property;

  @override
  void initState() {
    super.initState();
    widget.value.addListener(_listener);
  }

  @override
  void dispose() {
    widget.value.removeListener(_listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PropertyChangeModel<T>(
      state: this,
      child: widget.child,
    );
  }

  void _listener(Object property) {
    setState(() {
      _property = property;
    });
  }
}

/// The [InheritedModel] subclass that is rebuilt by [_PropertyChangeProviderState]
/// whenever its [PropertyChangeNotifier] is updated. Notifies dependents when the
/// name of the changed property is contained in the list of properties provided
/// when the widgets originally called the [PropertyChangeProvider].[of] method.
/// The type parameter [T] is the type of the [PropertyChangeNotifier] subclass.
class PropertyChangeModel<T extends PropertyChangeNotifier> extends InheritedModel {
  final _PropertyChangeProviderState _state;

  PropertyChangeModel({
    Key key,
    _PropertyChangeProviderState state,
    Widget child,
  })  : _state = state,
        super(key: key, child: child);

  /// The instance of [T] originally provided to the [PropertyChangeProvider] constructor.
  T get value => _state.widget.value;

  /// The name of the property that was last changed on the [value] instance.
  Object get property => _state._property;

  @override
  bool updateShouldNotify(PropertyChangeModel oldWidget) {
    return true;
  }

  @override
  bool updateShouldNotifyDependent(PropertyChangeModel<T> oldWidget, Set<Object> aspects) {
    return aspects.contains(_state._property);
  }
}
