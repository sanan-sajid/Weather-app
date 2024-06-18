import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:weather_app/envdata.dart';
import 'package:weather_app/weather_forecast_item.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({Key? key}) : super(key: key);

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  TextEditingController _cityNameController = TextEditingController();
  late Future<Map<String, dynamic>> _weatherData;

  @override
  void initState() {
    super.initState();
    _weatherData = getWeatherData(cityName: 'Delhi');
  }

  Future<Map<String, dynamic>> getWeatherData(
      {required String cityName}) async {
    try {
      final res = await http.get(
        Uri.parse(
          'https://api.openweathermap.org/data/2.5/forecast?q=$cityName&APPID=$weatherapikey',
        ),
      );
      final data = jsonDecode(res.body);
      if (data['cod'] != '200') {
        throw 'An unexpected error occurred / API limit exceeded';
      }
      return data;
    } catch (e) {
      throw e.toString();
    }
  }

  Future<void> updateWeather() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter City Name'),
          content: TextField(
            controller: _cityNameController,
            decoration: const InputDecoration(hintText: "Enter city name"),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Search'),
              onPressed: () {
                Navigator.of(context).pop();
                String cityName = _cityNameController.text.trim();
                if (cityName.isNotEmpty) {
                  setState(() {
                    _weatherData = getWeatherData(cityName: cityName);
                  });
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Weather App',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: updateWeather,
            icon: const Icon(Icons.search),
            tooltip: 'Search',
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _weatherData = getWeatherData(cityName: 'Lucknow');
              });
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: FutureBuilder(
        future: _weatherData,
        builder: (context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final data = snapshot.data!;
          final currentWeatherData = data['list'][0];
          final currentTemp = currentWeatherData['main']['temp'];
          final currentSky = currentWeatherData['weather'][0]['main'];
          final pressure = currentWeatherData['main']['pressure'];
          final windspeed = currentWeatherData['wind']['speed'];
          final humidity = currentWeatherData['main']['humidity'];
          final tempInCelsius = currentTemp - 273.15;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Main weather card
                SizedBox(
                  width: double.infinity,
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 20,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: 10,
                          sigmaY: 10,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 16, bottom: 16),
                          child: Column(
                            children: [
                              Text(
                                '${tempInCelsius.toStringAsFixed(2)}° C',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(
                                height: 16,
                              ),
                              Icon(
                                currentSky == 'Clouds'
                                    ? Icons.cloud
                                    : currentSky == 'Clear'
                                        ? Icons.wb_sunny
                                        : currentSky == 'Rain'
                                            ? Icons.beach_access
                                            : Icons.wb_twilight,
                                size: 64,
                              ),
                              const SizedBox(
                                height: 16,
                              ),
                              Text(
                                '$currentSky , ${data['city']['name']}',
                                style: const TextStyle(
                                  fontSize: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                  height: 20,
                ),

                // Weather forecast
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Weather Forecast',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 12,
                ),

                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (int i = 0; i < 7; i++)
                        HourlyForecast(
                          time: data['list'][i]['dt_txt']
                              .toString()
                              .substring(11, 16),
                          icon: data['list'][i]['weather'][0]['main'] ==
                                  'Clouds'
                              ? Icons.cloud
                              : data['list'][i]['weather'][0]['main'] == 'Clear'
                                  ? Icons.wb_sunny
                                  : data['list'][i]['weather'][0]['main'] ==
                                          'Rain'
                                      ? Icons.beach_access
                                      : Icons.wb_twilight,
                          temp: (data['list'][i]['main']['temp'] - 273.15)
                              .toStringAsFixed(2),
                        ),
                    ],
                  ),
                ),

                // Additional information card
                const SizedBox(
                  height: 16,
                ),

                // const Align(
                //   alignment: Alignment.centerLeft,
                //   child: Text(
                //     'Additional Information',
                //     style: TextStyle(
                //       fontSize: 24,
                //       fontWeight: FontWeight.bold,
                //     ),
                //   ),
                // ),

                const SizedBox(
                  height: 16,
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // AdditionalInfoItem(
                    //   icon: Icons.water_drop,
                    //   label: 'Humidity',
                    //   value: humidity.toString(),
                    // ),
                    // AdditionalInfoItem(
                    //   icon: Icons.air_rounded,
                    //   label: 'Windspeed',
                    //   value: windspeed.toString(),
                    // ),
                    // AdditionalInfoItem(
                    //   icon: Icons.beach_access,
                    //   label: 'Pressure',
                    //   value: pressure.toString(),
                    // ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
