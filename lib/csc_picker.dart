library csc_picker;

import 'package:csc_picker/dropdown_with_search.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'model/select_status_model.dart';

enum Layout { vertical, horizontal }

enum CountryFlag { SHOW_IN_DROP_DOWN_ONLY, ENABLE, DISABLE }

enum CscCountry {
  United_Kingdom,
  United_States,
   Canada,
   Nigeria
}

const Map<CscCountry, int> Countries = {
  United_Kingdom: 0,
  United_States: 1,
   Canada: 2,
   Nigeria  : 3
};

class CSCPicker extends StatefulWidget {
  ///CSC Picker Constructor
  const CSCPicker({
    Key? key,
    this.onCountryChanged,
    this.onStateChanged,
    this.onCityChanged,
    this.selectedItemStyle,
    this.dropdownHeadingStyle,
    this.dropdownItemStyle,
    this.dropdownDecoration,
    this.disabledDropdownDecoration,
    this.searchBarRadius,
    this.dropdownDialogRadius,
    this.flagState = CountryFlag.ENABLE,
    this.layout = Layout.horizontal,
    this.showStates = true,
    this.showCities = true,
    this.defaultCountry,
    this.currentCountry,
    this.currentState,
    this.currentCity,
    this.disableCountry = false,
    this.countrySearchPlaceholder = "Search Country",
    this.stateSearchPlaceholder = "Search State",
    this.citySearchPlaceholder = "Search City",
    this.countryDropdownLabel = "Country",
    this.stateDropdownLabel = "State",
    this.cityDropdownLabel = "City",
    this.countryFilter,
    this.title,
    this.clearButtonContent = const Text("Clear"),
    this.showClearButton = false,
  }) : super(key: key);

  final ValueChanged<String?>? onCountryChanged;
  final ValueChanged<String?>? onStateChanged;
  final ValueChanged<String?>? onCityChanged;

  final String? currentCountry;
  final String? currentState;
  final String? currentCity;

  final bool disableCountry;

  // clear button parameters
  final bool showClearButton;
  final Widget clearButtonContent;

  // title widget
  final Widget? title;

  ///Parameters to change style of CSC Picker
  final TextStyle? selectedItemStyle, dropdownHeadingStyle, dropdownItemStyle;
  final BoxDecoration? dropdownDecoration, disabledDropdownDecoration;
  final bool showStates, showCities;
  final CountryFlag flagState;
  final Layout layout;
  final double? searchBarRadius;
  final double? dropdownDialogRadius;

  final CscCountry? defaultCountry;

  final String countrySearchPlaceholder;
  final String stateSearchPlaceholder;
  final String citySearchPlaceholder;

  final String countryDropdownLabel;
  final String stateDropdownLabel;
  final String cityDropdownLabel;

  final List<CscCountry>? countryFilter;

  @override
  CSCPickerState createState() => CSCPickerState();
}

class CSCPickerState extends State<CSCPicker> {
  List<String?> _cities = [];
  List<String?> _country = [];
  List<String?> _states = [];
  List<CscCountry> _countryFilter = [];

  String _selectedCity = 'City';
  String? _selectedCountry;
  String _selectedState = 'State';
  var responses;

  @override
  void initState() {
    super.initState();
    setDefaults();
    if (widget.countryFilter != null) {
      _countryFilter = widget.countryFilter!;
    }
    getCountries();
    _selectedCity = widget.cityDropdownLabel;
    _selectedState = widget.stateDropdownLabel;
  }

  Future<void> setDefaults() async {
    if (widget.currentCountry != null) {
      setState(() => _selectedCountry = widget.currentCountry);
      await getStates();
    }

    if (widget.currentState != null) {
      setState(() => _selectedState = widget.currentState!);
      await getCities();
    }

    if (widget.currentCity != null) {
      setState(() => _selectedCity = widget.currentCity!);
    }
  }

  void _setDefaultCountry() {
    if (widget.defaultCountry != null) {
      print(_country[Countries[widget.defaultCountry]!]);
      _onSelectedCountry(_country[Countries[widget.defaultCountry]!]!);
    }
  }

  ///Read JSON country data from assets
  Future<dynamic> getResponse() async {
    var res = await rootBundle
        .loadString('packages/csc_picker/lib/assets/country.json');
    return jsonDecode(res);
  }

  ///get countries from json response
  Future<List<String?>> getCountries() async {
    _country.clear();
    var countries = await getResponse() as List;
    if (_countryFilter.isNotEmpty) {
      _countryFilter.forEach((element) {
        var result = countries[Countries[element]!];
        if (result != null) addCountryToList(result);
      });
    } else {
      countries.forEach((data) {
        addCountryToList(data);
      });
    }
    _setDefaultCountry();
    return _country;
  }

  ///Add a country to country list
  void addCountryToList(data) {
    var model = Country();
    model.name = data['name'];
    model.emoji = data['emoji'];
    if (!mounted) return;
    setState(() {
      widget.flagState == CountryFlag.ENABLE ||
              widget.flagState == CountryFlag.SHOW_IN_DROP_DOWN_ONLY
          ? _country.add(model.emoji! +
              "    " +
              model.name!) /* : _country.add(model.name)*/
          : _country.add(model.name);
    });
  }

  ///get states from json response
  Future<List<String?>> getStates() async {
    _states.clear();
    //print(_selectedCountry);
    var response = await getResponse();
    var takeState = widget.flagState == CountryFlag.ENABLE ||
            widget.flagState == CountryFlag.SHOW_IN_DROP_DOWN_ONLY
        ? response
            .map((map) => Country.fromJson(map))
            .where(
                (item) => item.emoji + "    " + item.name == _selectedCountry)
            .map((item) => item.state)
            .toList()
        : response
            .map((map) => Country.fromJson(map))
            .where((item) => item.name == _selectedCountry)
            .map((item) => item.state)
            .toList();
    var states = takeState as List;
    states.forEach((f) {
      if (!mounted) return;
      setState(() {
        var name = f.map((item) => item.name).toList();
        for (var stateName in name) {
          //print(stateName.toString());
          _states.add(stateName.toString());
        }
      });
    });
    _states.sort((a, b) => a!.compareTo(b!));
    return _states;
  }

  ///get cities from json response
  Future<List<String?>> getCities() async {
    _cities.clear();
    var response = await getResponse();
    var takeCity = widget.flagState == CountryFlag.ENABLE ||
            widget.flagState == CountryFlag.SHOW_IN_DROP_DOWN_ONLY
        ? response
            .map((map) => Country.fromJson(map))
            .where(
                (item) => item.emoji + "    " + item.name == _selectedCountry)
            .map((item) => item.state)
            .toList()
        : response
            .map((map) => Country.fromJson(map))
            .where((item) => item.name == _selectedCountry)
            .map((item) => item.state)
            .toList();
    var cities = takeCity as List;
    cities.forEach((f) {
      var name = f.where((item) => item.name == _selectedState);
      var cityName = name.map((item) => item.city).toList();
      cityName.forEach((ci) {
        if (!mounted) return;
        setState(() {
          var citiesName = ci.map((item) => item.name).toList();
          for (var cityName in citiesName) {
            //print(cityName.toString());
            _cities.add(cityName.toString());
          }
        });
      });
    });
    _cities.sort((a, b) => a!.compareTo(b!));
    return _cities;
  }

  ///get methods to catch newly selected country state and city and populate state based on country, and city based on state
  void _onSelectedCountry(String value) {
    if (!mounted) return;
    setState(() {
      if (widget.flagState == CountryFlag.SHOW_IN_DROP_DOWN_ONLY) {
        try {
          this.widget.onCountryChanged!(value.substring(6).trim());
        } catch (e) {}
      } else
        this.widget.onCountryChanged!(value);
      //code added in if condition
      if (value != _selectedCountry) {
        _states.clear();
        _cities.clear();
        _selectedState = widget.stateDropdownLabel;
        _selectedCity = widget.cityDropdownLabel;
        this.widget.onStateChanged!(null);
        this.widget.onCityChanged!(null);
        _selectedCountry = value;
        getStates();
      } else {
        this.widget.onStateChanged!(_selectedState);
        this.widget.onCityChanged!(_selectedCity);
      }
    });
  }

  void _onSelectedState(String value) {
    if (!mounted) return;
    setState(() {
      this.widget.onStateChanged!(value);
      //code added in if condition
      if (value != _selectedState) {
        _cities.clear();
        _selectedCity = widget.cityDropdownLabel;
        this.widget.onCityChanged!(null);
        _selectedState = value;
        getCities();
      } else {
        this.widget.onCityChanged!(_selectedCity);
      }
    });
  }

  void _onSelectedCity(String value) {
    if (!mounted) return;
    setState(() {
      //code added in if condition
      if (value != _selectedCity) {
        _selectedCity = value;
        this.widget.onCityChanged!(value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.title != null || widget.showClearButton)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (widget.title != null) Expanded(flex: 2, child: widget.title!),
              if (widget.showClearButton)
                Expanded(flex: 1, child: clearButton()),
            ],
          ),
        if (widget.title != null || widget.showClearButton)
          const SizedBox(
            height: 10.0,
          ),
        widget.layout == Layout.vertical
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  countryDropdown(),
                  SizedBox(
                    height: 10.0,
                  ),
                  stateDropdown(),
                  SizedBox(
                    height: 10.0,
                  ),
                  cityDropdown()
                ],
              )
            : Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      Expanded(child: countryDropdown()),
                      widget.showStates
                          ? SizedBox(
                              width: 10.0,
                            )
                          : Container(),
                      widget.showStates
                          ? Expanded(child: stateDropdown())
                          : Container(),
                    ],
                  ),
                  SizedBox(
                    height: 10.0,
                  ),
                  widget.showStates && widget.showCities
                      ? cityDropdown()
                      : Container()
                ],
              ),
      ],
    );
  }

  ///filter Country Data according to user input
  Future<List<String?>> getCountryData(filter) async {
    var filteredList = _country
        .where(
            (country) => country!.toLowerCase().contains(filter.toLowerCase()))
        .toList();
    if (filteredList.isEmpty)
      return _country;
    else
      return filteredList;
  }

  ///filter Sate Data according to user input
  Future<List<String?>> getStateData(filter) async {
    var filteredList = _states
        .where((state) => state!.toLowerCase().contains(filter.toLowerCase()))
        .toList();
    if (filteredList.isEmpty)
      return _states;
    else
      return filteredList;
  }

  ///filter City Data according to user input
  Future<List<String?>> getCityData(filter) async {
    var filteredList = _cities
        .where((city) => city!.toLowerCase().contains(filter.toLowerCase()))
        .toList();
    if (filteredList.isEmpty)
      return _cities;
    else
      return filteredList;
  }

  ///Country Dropdown Widget
  Widget countryDropdown() {
    return DropdownWithSearch(
      title: widget.countryDropdownLabel,
      placeHolder: widget.countrySearchPlaceholder,
      selectedItemStyle: widget.selectedItemStyle,
      dropdownHeadingStyle: widget.dropdownHeadingStyle,
      itemStyle: widget.dropdownItemStyle,
      decoration: widget.dropdownDecoration,
      disabledDecoration: widget.disabledDropdownDecoration,
      disabled: _country.length == 0 || widget.disableCountry ? true : false,
      dialogRadius: widget.dropdownDialogRadius,
      searchBarRadius: widget.searchBarRadius,
      label: widget.countrySearchPlaceholder,
      items: _country.map((String? dropDownStringItem) {
        return dropDownStringItem;
      }).toList(),
      selected: _selectedCountry != null
          ? _selectedCountry
          : widget.countryDropdownLabel,
      //selected: _selectedCountry != null ? _selectedCountry : "Country",
      //onChanged: (value) => _onSelectedCountry(value),
      onChanged: (value) {
        print("countryChanged $value $_selectedCountry");
        if (value != null) {
          _onSelectedCountry(value);
        }
      },
    );
  }

  ///State Dropdown Widget
  Widget stateDropdown() {
    return DropdownWithSearch(
      title: widget.stateDropdownLabel,
      placeHolder: widget.stateSearchPlaceholder,
      disabled: _states.length == 0 ? true : false,
      items: _states.map((String? dropDownStringItem) {
        return dropDownStringItem;
      }).toList(),
      selectedItemStyle: widget.selectedItemStyle,
      dropdownHeadingStyle: widget.dropdownHeadingStyle,
      itemStyle: widget.dropdownItemStyle,
      decoration: widget.dropdownDecoration,
      dialogRadius: widget.dropdownDialogRadius,
      searchBarRadius: widget.searchBarRadius,
      disabledDecoration: widget.disabledDropdownDecoration,
      selected: _selectedState,
      label: widget.stateSearchPlaceholder,
      //onChanged: (value) => _onSelectedState(value),
      onChanged: (value) {
        //print("stateChanged $value $_selectedState");
        value != null
            ? _onSelectedState(value)
            : _onSelectedState(_selectedState);
      },
    );
  }

  ///City Dropdown Widget
  Widget cityDropdown() {
    return DropdownWithSearch(
      title: widget.cityDropdownLabel,
      placeHolder: widget.citySearchPlaceholder,
      disabled: _cities.length == 0 ? true : false,
      items: _cities.map((String? dropDownStringItem) {
        return dropDownStringItem;
      }).toList(),
      selectedItemStyle: widget.selectedItemStyle,
      dropdownHeadingStyle: widget.dropdownHeadingStyle,
      itemStyle: widget.dropdownItemStyle,
      decoration: widget.dropdownDecoration,
      dialogRadius: widget.dropdownDialogRadius,
      searchBarRadius: widget.searchBarRadius,
      disabledDecoration: widget.disabledDropdownDecoration,
      selected: _selectedCity,
      label: widget.citySearchPlaceholder,
      //onChanged: (value) => _onSelectedCity(value),
      onChanged: (value) {
        //print("cityChanged $value $_selectedCity");
        value != null ? _onSelectedCity(value) : _onSelectedCity(_selectedCity);
      },
    );
  }

  Widget clearButton() {
    return ElevatedButton(
      onPressed: () => clearFields(),
      child: widget.clearButtonContent,
    );
  }

  clearFields() {
    if (this.widget.onCountryChanged != null)
      this.widget.onCountryChanged!(null);
    _states.clear();
    _cities.clear();
    _selectedState = widget.stateDropdownLabel;
    _selectedCity = widget.cityDropdownLabel;
    if (this.widget.onStateChanged != null) this.widget.onStateChanged!(null);
    if (this.widget.onCityChanged != null) this.widget.onCityChanged!(null);
    _selectedCountry = null;
    getStates();
  }
}
