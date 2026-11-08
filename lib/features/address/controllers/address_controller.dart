import 'package:ride_sharing_user_app/helper/safe_location.dart';
import 'dart:async';
import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/data/api_checker.dart';
import 'package:ride_sharing_user_app/features/address/domain/services/address_service_interface.dart';
import 'package:ride_sharing_user_app/features/location/controllers/location_controller.dart';
import 'package:ride_sharing_user_app/helper/display_helper.dart';
import 'package:ride_sharing_user_app/util/app_constants.dart';
import 'package:ride_sharing_user_app/util/images.dart';
import 'package:ride_sharing_user_app/features/address/domain/models/address_model.dart';
import 'package:shared_preferences/shared_preferences.dart';


class AddressController extends GetxController implements GetxService {
  final AddressServiceInterface addressServiceInterface;
  AddressController({required this.addressServiceInterface});

  List<Address>? addressList;
  List<Address> recentAddressList = [];

  bool isLoading = false;
  int? _currentIndex = 0;
  int? get currentIndex => _currentIndex;

  List<AddressTypeModel> addressTypeList = [
    AddressTypeModel('home', Images.homeIcon),
    AddressTypeModel('office', Images.workIcon),
    AddressTypeModel('others', Images.otherIcon),
    ];

  int _selectAddressIndex = 0;

  int get selectAddressIndex => _selectAddressIndex;
  String  selectAddress = 'home';

  void updateAddressIndex(int index, bool notify) {
    _selectAddressIndex = index;
    selectAddress = addressTypeList[_selectAddressIndex].title;
    if(notify) {
      update();
    }
  }

  Future<void> addNewAddress(Address address, {bool updateAddress = false}) async {
    isLoading = true;
    update();
    Response response;
    if(updateAddress){
      response = await addressServiceInterface.update(address);
    }else{
      response = await addressServiceInterface.add(address);
    }
    if(response.statusCode == 200) {
      getAddressList(1);
      Get.back();
      isLoading = false;
      Get.find<LocationController>().clearAddAddress();
      showCustomSnackBar(updateAddress ?'address_updated_successfully'.tr : 'address_added_successfully'.tr, isError: false);
    }else{
      ApiChecker.checkApi(response);
    }
    isLoading = false;
    update();

  }

  Future<void> getAddressList(int offset) async {
    isLoading = true;

    Response? response = await addressServiceInterface.getList(offset : offset);
    if(response!.statusCode == 200 && response.body['data'] != null){
      addressList = [];
      isLoading = false;
      addressList!.addAll(AddressModel.fromJson(response.body).data!);
    }else{
      isLoading = false;
      ApiChecker.checkApi(response);
    }
    isLoading = false;
    update();

  }

  Future<void> deleteAddress(String addressId) async {
    isLoading = true;
    update();
    Response? response = await addressServiceInterface.delete(addressId);
    if(response!.statusCode == 200){
      Get.back();
      isLoading = false;
      getAddressList(1);
      showCustomSnackBar('address_deleted_successfully'.tr, isError: false);
    }else{
      ApiChecker.checkApi(response);
    }
    isLoading = false;
    update();

  }

  void setCurrentIndex(int index, bool notify) {
    _currentIndex = index;
    if(notify) {
      update();
    }
  }

  Timer? _timer;
  void updateLastLocation(){
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) async{
      final location = await SafeLocation.currentPosition();
      if (location == null) return; // permission denied / service off: skip this tick
      await addressServiceInterface.updateLastLocation(location.latitude.toString(), location.longitude.toString(), Get.find<LocationController>().zoneID ?? '');
    });
  }

  Future<void> getRecentAddressList() async {
    final prefs = Get.find<SharedPreferences>();
    final String? cached = prefs.getString(AppConstants.searchAddress);
    if (cached != null && cached.isNotEmpty) {
      try {
        final List decoded = jsonDecode(cached);
        recentAddressList = decoded.map((e) => Address.fromJson(e)).toList();
      } catch (_) {}
    }

    try {
      Response? response = await addressServiceInterface.getRecentAddressList();
      if (response != null && response.statusCode == 200 && response.body['data'] != null) {
        final List<dynamic> data = response.body['data'];
        for (var item in data) {
          final addr = Address.fromJson(item);
          if (addr.address != null &&
              addr.address!.trim().isNotEmpty &&
              !recentAddressList.any((a) => a.address?.trim() == addr.address?.trim())) {
            recentAddressList.add(addr);
          }
        }
        if (recentAddressList.isNotEmpty) {
          prefs.setString(
            AppConstants.searchAddress,
            jsonEncode(recentAddressList.map((e) => e.toJson()).toList()),
          );
        }
      }
    } catch (_) {}

    update();
  }

  void addRecentAddress(Address address) {
    if (address.address == null || address.address!.trim().isEmpty) return;
    recentAddressList.removeWhere((item) =>
        item.address?.trim().toLowerCase() == address.address?.trim().toLowerCase());
    recentAddressList.insert(0, address);
    if (recentAddressList.length > 10) {
      recentAddressList = recentAddressList.sublist(0, 10);
    }
    try {
      final prefs = Get.find<SharedPreferences>();
      prefs.setString(
        AppConstants.searchAddress,
        jsonEncode(recentAddressList.map((e) => e.toJson()).toList()),
      );
    } catch (_) {}
    update();
  }

  void clearRecentAddresses() {
    recentAddressList.clear();
    try {
      final prefs = Get.find<SharedPreferences>();
      prefs.remove(AppConstants.searchAddress);
    } catch (_) {}
    update();
  }

}


class AddressTypeModel{
  final String title;
  final String icon;

  AddressTypeModel(this.title, this.icon);
}