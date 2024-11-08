import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MiAppPokemon());
}

class MiAppPokemon extends StatelessWidget {
  const MiAppPokemon({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pokémon',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MiPaginaPrincipalPokemon(titulo: 'Pokémon'),
    );
  }
}

class MiPaginaPrincipalPokemon extends StatefulWidget {
  const MiPaginaPrincipalPokemon({super.key, required this.titulo});
  final String titulo;

  @override
  State<MiPaginaPrincipalPokemon> createState() => _MiPaginaPrincipalPokemonState();
}

class _MiPaginaPrincipalPokemonState extends State<MiPaginaPrincipalPokemon> {
  List<dynamic> listaPokemon = [];
  List<dynamic> listaPokemonFiltrada = [];
  int paginaActual = 1;
  final int limite = 12;
  String consultaBusqueda = "";

  @override
  void initState() {
    super.initState();
    obtenerPokemon();
  }

  Future<void> obtenerPokemon() async {
    final offset = (paginaActual - 1) * limite;
    final response = await http.get(Uri.parse('https://pokeapi.co/api/v2/pokemon?limit=$limite&offset=$offset'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        listaPokemon = data['results'];
        listaPokemonFiltrada = listaPokemon;
      });
    }
  }

  void buscarPokemonPorNombre(String query) {
    setState(() {
      consultaBusqueda = query.toLowerCase();
      listaPokemonFiltrada = listaPokemon
          .where((pokemon) => pokemon['name'].toLowerCase().contains(consultaBusqueda))
          .toList();
    });
  }

  void siguientePagina() {
    setState(() {
      paginaActual++;
      obtenerPokemon();
    });
  }

  void paginaAnterior() {
    if (paginaActual > 1) {
      setState(() {
        paginaActual--;
        obtenerPokemon();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
      backgroundColor: Colors.blue,
      title: Row(
        children: [
          const Text(
            'Pokémon',
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              onChanged: buscarPokemonPorNombre,
              decoration: const InputDecoration(
                hintText: 'Buscar Pokémon...',
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.white60),
              ),
              style: const TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
    ),
    body: listaPokemonFiltrada.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: listaPokemonFiltrada.length,
              itemBuilder: (context, index) {
                final pokemon = listaPokemonFiltrada[index];
                return TarjetaPokemon(pokemon: pokemon);
              },
            ),

          bottomNavigationBar: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                onPressed: paginaActual > 1 ? paginaAnterior : null,
                child: const Icon(Icons.arrow_back),
              ),
              Text('$paginaActual'),
              ElevatedButton(
                onPressed: listaPokemon.length == limite ? siguientePagina : null,
                child: const Icon(Icons.arrow_forward),
              ),
            ],
          ),
        ),        

    );
  }
}

class TarjetaPokemon extends StatelessWidget {
  final dynamic pokemon;

  const TarjetaPokemon({Key? key, required this.pokemon}) : super(key: key);

  Future<String> obtenerImagenPokemon(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['sprites']['front_default'] ?? '';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: obtenerImagenPokemon(pokemon['url']),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        return Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.network(
                snapshot.data ?? '',
                width: 50,
                height: 50,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
              ),
              Text(pokemon['name']),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PantallaDetallePokemon(urlPokemon: pokemon['url']),
                    ),
                  );
                },
                child: const Text("Ver más"),
              ),
            ],
          ),
        );
      },
    );
  }
}


class PantallaDetallePokemon extends StatelessWidget {
  final String urlPokemon;

  const PantallaDetallePokemon({Key? key, required this.urlPokemon}) : super(key: key);

  Future<Map<String, dynamic>> obtenerDetallesPokemon() async {
    final response = await http.get(Uri.parse(urlPokemon));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return {};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Detalles del Pokémon"),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: obtenerDetallesPokemon(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasData) {
            final datosPokemon = snapshot.data!;
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.network(datosPokemon['sprites']['front_default'] ?? ''),
                  const SizedBox(height: 16),
                  Text(
                    datosPokemon['name'].toString().toUpperCase(),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text("Altura: ${datosPokemon['height']}"),
                  Text("Peso: ${datosPokemon['weight']}"),
                  const SizedBox(height: 16),
                  Text(
                    "Habilidades:",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Column(
                    children: (datosPokemon['abilities'] as List)
                        .map((habilidad) => Text(habilidad['ability']['name']))
                        .toList(),
                  ),
                ],
              ),
            );
          } else {
            return const Center(child: Text("No se pudo cargar los detalles."));
          }
        },
      ),
    );
  }
}
