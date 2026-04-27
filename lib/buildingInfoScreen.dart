
import 'dart:collection';
import 'dart:developer';
import 'dart:io';

import 'package:admin/map.dart';
import 'package:admin/mapDemoScreen.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/svg.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart' as g;
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:permission_handler/permission_handler.dart';
import 'API/buildingAllApi.dart';
import 'APIMODELS/Building.dart';
import 'APIMODELS/buildingAll.dart';
import 'HelperClass.dart';
import 'UserLog.dart';
import 'api/buildingAPI.dart';
import 'fingerprinting/fingerprinting.dart';
class BuildingInfoScreen extends StatefulWidget {
  List<buildingAll>? receivedAllBuildingList;
  String? venueTitle;
  String? venueDescription;
  String? venueCategory;
  String? venueAddress;
  String? venuePhone;
  String? venueWebsite;
  int? dist;
  Position? currentLatLng;
  String? frmMainScreen;

  BuildingInfoScreen({ this.receivedAllBuildingList,this.venueTitle,this.venueDescription,this.venueCategory,this.venueAddress,this.venuePhone,this.venueWebsite,this.dist,this.currentLatLng,this.frmMainScreen});

  @override
  State<BuildingInfoScreen> createState() => _BuildingInfoScreenState();
}

class _BuildingInfoScreenState extends State<BuildingInfoScreen> {
  late List<buildingAll> allBuildingList=[];
  final Fingerprinting _fingerprinting = Fingerprinting();
  BuildingData? dd;
  HashMap<String,g.LatLng> allBuildingID = new HashMap();
  String truncateString(String input, int maxLength) {
    if (input.length <= maxLength) {
      return input;
    } else {
      return input.substring(0, maxLength - 2) + '..';
    }
  }
  String makeAddress(String inputString) {
    List<String> words = inputString.split(',');
    // Ensure there are at least three words before extracting the last three
    if (words.length > 3) {
      return words[words.length-3]+","+words[words.length-4];
    } else {
      // Handle the case when there are fewer than three words
      return "";
    }
  }
  bool bluetoohEnabled = false;

  @override
  void initState() {
    super.initState();
    print(widget.receivedAllBuildingList);
    // allBuildingID["65d9cacfdb333f8945861f0f"] =  g.LatLng(28.9469, 77.1011);
    apiCall();
    print("building list");
    WidgetsBinding.instance.addPostFrameCallback((_) {
    });
    // widget.receivedAllBuildingList!.forEach((element) {
    //   g.LatLng kk = g.LatLng(element.coordinates![0], element.coordinates![1]);
    //   allBuildingID[element.sId!] = kk;
    // });

    // controller.executeFunction();

  }
  // Get user's current location
bool isLoading=false;
  void apiCall() async {
    BuildingAPI().fetchBuildData().then((value){
      // for(int i=0;i<value.length;i++){
      //   print("value we got of building:${value[i]}");
      // }
      setState(() {
        dd = value;
      });
    });
    setState(() {
      isLoading=true;
    });
    print("API CAll");
  }
  var currentData;

  @override
  Widget build(BuildContext context) {

    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          leading: Container(
            alignment: Alignment.centerRight,
            width: 60,
            child: Container(
                child: Semantics(
                  label: 'Back',
                  child: IconButton(
                      onPressed: (){
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.arrow_back_ios,color: Colors.black,)
                  ),
                )
            ),
          ),
          backgroundColor: Colors.transparent, // Set the background color to transparent
          elevation: 0,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFFFFF), Color(0xFFFFFFFF)], // Set your gradient colors
              ),
            ),
          ),
        ),
        body: SingleChildScrollView(
          child: Container(
            height: screenHeight+250,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IntrinsicWidth(
                  child: Container(
                    height: 22,
                    margin: EdgeInsets.only(top: 20,left: 18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                          colors: [Color(0xff0f98B5),Color(0xff872DE1)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight
                      ),
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child:(dd!=null && dd!.buildings!=null && dd!.campus!=null)?
                    Row(
                      children: [
                        Container(margin: EdgeInsets.only(left: 8,right: 8),child: Icon(Icons.school_outlined,color: Colors.white,size: 17,)),
                        Container(
                          margin: EdgeInsets.only(right: 8),
                          child: Text(
                           "${dd!.buildings!.first.venueCategory}"??"No category",
                            style: const TextStyle(
                              fontFamily: "Roboto",
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Color(0xffffffff),
                              height: 18/12,
                            ),
                            textAlign: TextAlign.left,
                          ),
                        )
                      ],
                    ):Container(),
                  ),
                ),
                (dd!=null && dd!.buildings!=null && dd!.campus!=null)? IntrinsicHeight(
                  child: Container(
                    margin: EdgeInsets.only(top: 6,left: 16),
                    child: Text(
                      buildingAllApi.selectedVenue??"",
                      style: const TextStyle(
                        fontFamily: "Roboto",
                        fontSize: 20,
                        fontWeight: FontWeight.w400,
                        color: Color(0xff000000),
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                ):Container(),
                (dd!=null && dd!.buildings!=null && dd!.campus!=null)? Container(
                  margin: EdgeInsets.only(left: 16,top: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(Icons.location_on_outlined,size: 15,color: Color(0xff8D8C8C),),
                      SizedBox(width: 8,),
                      Container(
                        child: Text(
                          truncateString(makeAddress(dd!.buildings!.first.address!) ?? "",25),
                          style: const TextStyle(
                            fontFamily: "Roboto",
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Color(0xff8d8c8c),
                            height: 20/14,
                          ),
                          textAlign: TextAlign.left,
                          maxLines: 3, // Set the maximum number of lines
                          overflow: TextOverflow.ellipsis, // Display '...' when overflowed
                        ),
                      ),
                      (dd!=null && dd!.buildings!=null && dd!.campus!=null)?

                      Container(
                        child:
                        InkWell(
                          child: Container(
                            decoration: BoxDecoration(
                                color:  Colors.white,
                                border: Border.all(
                                  color: Color(0xffEBEBEB),
                                ),
                                borderRadius: BorderRadius.all(Radius.circular(8))
                            ),
                          ),
                        ),
                      ):Container()
                    ],
                  ),
                ):Container(),
                Container(
                  margin: EdgeInsets.only(top: 32,left:16),
                  child: Text(
                    "Buildings",
                    style: const TextStyle(
                      fontFamily: "Roboto",
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                      color: Color(0xff000000),
                      height: 24/18,
                    ),
                    textAlign: TextAlign.left,
                  ),
                ),
                (isLoading && dd!=null)?
                Container(
                  height: 225,
                  child:(dd!=null || dd!.buildings!=null)?
                  ListView.builder(
                    scrollDirection:Axis.horizontal ,
                    itemBuilder: (context,index){
                      currentData = dd!.buildings![index];
                      return Container(
                        width: 208,
                        child: Container(
                          child:
                          ListTile(
                            onTap:(){
                              // buildingAllApi.selectedBuildingID=dd!.buildings![index].id.toString();
                              wsocket.message["AppInitialization"]["BID"]=dd!.buildings![index].id;
                              wsocket.message["AppInitialization"]["buildingName"]=dd!.buildings![index].venueName;
                              buildingAllApi.selectedVenue=dd!.buildings![index].venueName!;
                              buildingAllApi.selectedBuildingName=dd!.buildings![index].buildingName!;
                              buildingAllApi.isGlobalAnnotation=dd!.buildings![index].globalAnnotation;
                              setState((){});
                              print("allbuildingapi");
                              print("${buildingAllApi.selectedBuildingID} ${dd!.buildings![index].id} ${index}");

                              if(buildingAllApi.isGlobalAnnotation){
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MapDemoScreen(fingerprinting: _fingerprinting),
                                  ),
                                );
                              }else{
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => googleMap(fromPage: widget.frmMainScreen!, bid: dd!.buildings![index].id.toString(), bName: dd!.buildings![index].buildingName.toString(),),
                                  ),
                                );
                              }

                            },
                            title: Container(

                              decoration: BoxDecoration(
                                  color:  Colors.white,
                                  border: Border.all(
                                    color: Color(0xffEBEBEB),
                                  ),
                                  borderRadius: BorderRadius.all(Radius.circular(8))
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    width: 208,
                                    height: 117,
                                    padding: EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8),bottomLeft:Radius.circular(8),bottomRight: Radius.circular(8) ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8),bottomLeft:Radius.circular(8),bottomRight: Radius.circular(8)),
                                      child: Image.network(
                                        // "https://maps.iwayplus.in/uploads/${widget.imageURL}",
                                        "https://maps.iwayplus.in/uploads/${currentData.venuePhoto}",
                                        // You can replace the placeholder image URL with your default image URL
                                        errorBuilder: (context, error, stackTrace) {
                                          return Image.asset(
                                            'assets/default-image.jpg', // Replace with the path to your default image asset
                                            fit: BoxFit.fill,
                                          );
                                        },
                                        fit: BoxFit.fill,
                                      ),
                                    ),
                                  ),
                                  Container(
                                      alignment: Alignment.topLeft,
                                      margin: EdgeInsets.only(top: 10,left: 8),
                                      child: Text(
                                        HelperClass.truncateString(currentData.buildingName!,20),
                                        style: const TextStyle(
                                          fontFamily: "Roboto",
                                          fontSize: 16,
                                          fontWeight: FontWeight.w400,
                                          color: Color(0xff0c141c),
                                          height: 25/16,
                                        ),
                                        textAlign: TextAlign.left,
                                      )
                                  ),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                          margin: EdgeInsets.only(left: 8,top: 10),
                                          child: Text(
                                            currentData.venueCategory??"",
                                            style: const TextStyle(
                                              fontFamily: "Roboto",
                                              fontSize: 14,
                                              fontWeight: FontWeight.w400,
                                              color: Color(0xff4a4545),
                                              height: 20/14,
                                            ),
                                            textAlign: TextAlign.left,
                                          )
                                      ),
                                      Spacer(),
                                    ],
                                  ),


                                  // SizedBox(width: screenWidth/3.2,),

                                  Padding(
                                    padding: const EdgeInsets.only(right: 130),
                                    child: Container(height: 10,width: 10,decoration: BoxDecoration(color: (currentData.geofencing)?Colors.green:Colors.red,borderRadius: BorderRadius.circular(20)),),
                                  )
                                ],
                              ),
                            ),
                            // Container(
                            //   decoration: BoxDecoration(
                            //       border: Border.all(
                            //         color: Color(0xffEBEBEB),
                            //       ),
                            //       borderRadius: BorderRadius.all(Radius.circular(8))
                            //   ),
                            //   child: Column(
                            //     children: [
                            //       Container(
                            //         width: 188,
                            //         height: 117,
                            //         padding: EdgeInsets.all(5),
                            //         decoration: BoxDecoration(
                            //           borderRadius: BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8),bottomLeft:Radius.circular(8),bottomRight: Radius.circular(8) ),
                            //         ),
                            //         child: ClipRRect(
                            //           borderRadius: BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8),bottomLeft:Radius.circular(8),bottomRight: Radius.circular(8)),
                            //           child: Image.network(
                            //             // "https://maps.iwayplus.in/uploads/${widget.imageURL}",
                            //             "https://maps.iwayplus.in/uploads/${currentData.venuePhoto}",
                            //             // You can replace the placeholder image URL with your default image URL
                            //             errorBuilder: (context, error, stackTrace) {
                            //               return Image.asset(
                            //                 'assets/default-image.jpg', // Replace with the path to your default image asset
                            //                 fit: BoxFit.fill,
                            //               );
                            //             },
                            //             fit: BoxFit.fill,
                            //           ),
                            //         ),
                            //       ),
                            //       Container(
                            //           alignment: Alignment.topLeft,
                            //           margin: EdgeInsets.only(top: 0,left: 8),
                            //           child: Text(
                            //             HelperClass.truncateString(currentData.buildingName!,20),
                            //             style: const TextStyle(
                            //               fontFamily: "Roboto",
                            //               fontSize: 16,
                            //               fontWeight: FontWeight.w400,
                            //               color: Color(0xff0c141c),
                            //               height: 25/16,
                            //             ),
                            //             textAlign: TextAlign.left,
                            //           )
                            //       ),
                            //       Row(
                            //         crossAxisAlignment: CrossAxisAlignment.start,
                            //         children: [
                            //           Container(
                            //               margin: EdgeInsets.only(left: 8,top: 10),
                            //               child: Text(
                            //                 currentData.venueCategory??"",
                            //                 style: const TextStyle(
                            //                   fontFamily: "Roboto",
                            //                   fontSize: 14,
                            //                   fontWeight: FontWeight.w400,
                            //                   color: Color(0xff4a4545),
                            //                   height: 20/14,
                            //                 ),
                            //                 textAlign: TextAlign.left,
                            //               )
                            //           ),
                            //           Spacer(),
                            //           IconButton(
                            //             icon: Semantics(
                            //               label: 'Favourite',
                            //               child: Icon(
                            //                 isFavourite? Icons.favorite:
                            //                 Icons.favorite_border,size: 24,color: Colors.red,),
                            //             ),
                            //             onPressed: () async{
                            //               if(isFavourite){
                            //                 await value.delete(currentData.buildingName);
                            //               }else {
                            //                 await value.put(
                            //                     currentData.buildingName,
                            //                     currentData.buildingName);
                            //               }// Add your favorite button onPressed logic here
                            //               log('Favouties Database Size ${value.length}');
                            //             },
                            //           )
                            //         ],
                            //       ),
                            //     ],
                            //   ),
                            // ),

                          ),
                        ),
                      );
                      //   InsideBuildingCard(
                      //   buildingImageURL: currentData.venuePhoto?? "",
                      //   buildingName: currentData.buildingName?? "",
                      //   buildingTag: currentData.venueCategory?? "",
                      //   buildingId: currentData.sId??"",
                      //   buildingFavourite: false, allBuildingID: allBuildingID,
                      // );
                    },
                    itemCount:dd!.buildings!.length
                  ):Center(child: Text("No builidngs found for the current venue",style: TextStyle(fontSize: 30),),),
                ):Center(child: CircularProgressIndicator(color: Colors.cyan,),),
              ],
            ),
          ),
        ),


      ),
    );
  }
}
