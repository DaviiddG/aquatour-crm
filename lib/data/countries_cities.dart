class CountryData {
  final String name;
  final List<String> cities;
  final String currency;
  final String climate;
  final String language;

  const CountryData({
    required this.name,
    required this.cities,
    required this.currency,
    required this.climate,
    required this.language,
  });
}

const Map<String, CountryData> countriesData = {
  'Colombia': CountryData(
    name: 'Colombia',
    cities: ['Bogotá', 'Medellín', 'Cali', 'Cartagena', 'Barranquilla', 'Santa Marta', 'Pereira', 'Bucaramanga', 'Cúcuta', 'Manizales'],
    currency: 'COP',
    climate: 'Tropical, 18-28°C',
    language: 'Español',
  ),
  'México': CountryData(
    name: 'México',
    cities: ['Ciudad de México', 'Guadalajara', 'Monterrey', 'Cancún', 'Playa del Carmen', 'Puerto Vallarta', 'Los Cabos', 'Mérida', 'Oaxaca', 'Puebla'],
    currency: 'MXN',
    climate: 'Variado, 15-30°C',
    language: 'Español',
  ),
  'Estados Unidos': CountryData(
    name: 'Estados Unidos',
    cities: ['Nueva York', 'Los Ángeles', 'Miami', 'Las Vegas', 'Orlando', 'San Francisco', 'Chicago', 'Boston', 'Seattle', 'Washington D.C.'],
    currency: 'USD',
    climate: 'Variado, -5-35°C',
    language: 'Inglés',
  ),
  'España': CountryData(
    name: 'España',
    cities: ['Madrid', 'Barcelona', 'Sevilla', 'Valencia', 'Málaga', 'Bilbao', 'Granada', 'Palma de Mallorca', 'Ibiza', 'San Sebastián'],
    currency: 'EUR',
    climate: 'Mediterráneo, 10-30°C',
    language: 'Español',
  ),
  'Francia': CountryData(
    name: 'Francia',
    cities: ['París', 'Niza', 'Lyon', 'Marsella', 'Burdeos', 'Toulouse', 'Estrasburgo', 'Cannes', 'Montpellier', 'Nantes'],
    currency: 'EUR',
    climate: 'Templado, 5-25°C',
    language: 'Francés',
  ),
  'Italia': CountryData(
    name: 'Italia',
    cities: ['Roma', 'Milán', 'Venecia', 'Florencia', 'Nápoles', 'Turín', 'Bolonia', 'Verona', 'Pisa', 'Génova'],
    currency: 'EUR',
    climate: 'Mediterráneo, 8-30°C',
    language: 'Italiano',
  ),
  'Reino Unido': CountryData(
    name: 'Reino Unido',
    cities: ['Londres', 'Edimburgo', 'Manchester', 'Liverpool', 'Birmingham', 'Glasgow', 'Oxford', 'Cambridge', 'Brighton', 'Bristol'],
    currency: 'GBP',
    climate: 'Templado, 5-20°C',
    language: 'Inglés',
  ),
  'Alemania': CountryData(
    name: 'Alemania',
    cities: ['Berlín', 'Múnich', 'Frankfurt', 'Hamburgo', 'Colonia', 'Stuttgart', 'Düsseldorf', 'Dortmund', 'Essen', 'Leipzig'],
    currency: 'EUR',
    climate: 'Templado, 0-25°C',
    language: 'Alemán',
  ),
  'Brasil': CountryData(
    name: 'Brasil',
    cities: ['Río de Janeiro', 'São Paulo', 'Brasilia', 'Salvador', 'Fortaleza', 'Recife', 'Manaos', 'Florianópolis', 'Foz do Iguaçu', 'Búzios'],
    currency: 'BRL',
    climate: 'Tropical, 20-35°C',
    language: 'Portugués',
  ),
  'Argentina': CountryData(
    name: 'Argentina',
    cities: ['Buenos Aires', 'Mendoza', 'Córdoba', 'Bariloche', 'Ushuaia', 'Salta', 'Rosario', 'Mar del Plata', 'El Calafate', 'Iguazú'],
    currency: 'ARS',
    climate: 'Variado, -5-30°C',
    language: 'Español',
  ),
  'Perú': CountryData(
    name: 'Perú',
    cities: ['Lima', 'Cusco', 'Arequipa', 'Puno', 'Trujillo', 'Iquitos', 'Paracas', 'Máncora', 'Huaraz', 'Nazca'],
    currency: 'PEN',
    climate: 'Variado, 5-28°C',
    language: 'Español',
  ),
  'Chile': CountryData(
    name: 'Chile',
    cities: ['Santiago', 'Valparaíso', 'Viña del Mar', 'Puerto Varas', 'Punta Arenas', 'La Serena', 'Antofagasta', 'Concepción', 'Arica', 'Iquique'],
    currency: 'CLP',
    climate: 'Variado, -5-30°C',
    language: 'Español',
  ),
  'Ecuador': CountryData(
    name: 'Ecuador',
    cities: ['Quito', 'Guayaquil', 'Cuenca', 'Galápagos', 'Montañita', 'Baños', 'Manta', 'Salinas', 'Otavalo', 'Loja'],
    currency: 'USD',
    climate: 'Tropical, 15-30°C',
    language: 'Español',
  ),
  'Panamá': CountryData(
    name: 'Panamá',
    cities: ['Ciudad de Panamá', 'Bocas del Toro', 'Boquete', 'San Blas', 'Colón', 'David', 'Chitré', 'Pedasí', 'El Valle', 'Portobelo'],
    currency: 'USD',
    climate: 'Tropical, 24-32°C',
    language: 'Español',
  ),
  'Costa Rica': CountryData(
    name: 'Costa Rica',
    cities: ['San José', 'Manuel Antonio', 'Tamarindo', 'La Fortuna', 'Puerto Viejo', 'Monteverde', 'Jacó', 'Uvita', 'Nosara', 'Guanacaste'],
    currency: 'CRC',
    climate: 'Tropical, 20-30°C',
    language: 'Español',
  ),
  'República Dominicana': CountryData(
    name: 'República Dominicana',
    cities: ['Punta Cana', 'Santo Domingo', 'Puerto Plata', 'La Romana', 'Samaná', 'Bávaro', 'Cabarete', 'Juan Dolio', 'Bayahíbe', 'Las Terrenas'],
    currency: 'DOP',
    climate: 'Tropical, 25-32°C',
    language: 'Español',
  ),
  'Cuba': CountryData(
    name: 'Cuba',
    cities: ['La Habana', 'Varadero', 'Trinidad', 'Santiago de Cuba', 'Viñales', 'Cienfuegos', 'Santa Clara', 'Cayo Coco', 'Holguín', 'Camagüey'],
    currency: 'CUP',
    climate: 'Tropical, 22-32°C',
    language: 'Español',
  ),
  'Japón': CountryData(
    name: 'Japón',
    cities: ['Tokio', 'Kioto', 'Osaka', 'Hiroshima', 'Nara', 'Yokohama', 'Sapporo', 'Fukuoka', 'Nagoya', 'Okinawa'],
    currency: 'JPY',
    climate: 'Templado, 5-30°C',
    language: 'Japonés',
  ),
  'China': CountryData(
    name: 'China',
    cities: ['Pekín', 'Shanghái', 'Hong Kong', 'Xi\'an', 'Guilin', 'Chengdu', 'Hangzhou', 'Suzhou', 'Guangzhou', 'Shenzhen'],
    currency: 'CNY',
    climate: 'Variado, -10-35°C',
    language: 'Chino Mandarín',
  ),
  'Tailandia': CountryData(
    name: 'Tailandia',
    cities: ['Bangkok', 'Phuket', 'Chiang Mai', 'Pattaya', 'Krabi', 'Koh Samui', 'Ayutthaya', 'Hua Hin', 'Koh Phi Phi', 'Chiang Rai'],
    currency: 'THB',
    climate: 'Tropical, 25-35°C',
    language: 'Tailandés',
  ),
  'Emiratos Árabes Unidos': CountryData(
    name: 'Emiratos Árabes Unidos',
    cities: ['Dubái', 'Abu Dhabi', 'Sharjah', 'Ras Al Khaimah', 'Fujairah', 'Ajman', 'Al Ain', 'Umm Al Quwain'],
    currency: 'AED',
    climate: 'Desértico, 20-45°C',
    language: 'Árabe',
  ),
  'Turquía': CountryData(
    name: 'Turquía',
    cities: ['Estambul', 'Ankara', 'Antalya', 'Capadocia', 'Bodrum', 'Esmirna', 'Mármaris', 'Pamukkale', 'Éfeso', 'Fethiye'],
    currency: 'TRY',
    climate: 'Mediterráneo, 10-35°C',
    language: 'Turco',
  ),
  'Grecia': CountryData(
    name: 'Grecia',
    cities: ['Atenas', 'Santorini', 'Mykonos', 'Creta', 'Rodas', 'Corfú', 'Tesalónica', 'Zakynthos', 'Naxos', 'Paros'],
    currency: 'EUR',
    climate: 'Mediterráneo, 10-32°C',
    language: 'Griego',
  ),
  'Portugal': CountryData(
    name: 'Portugal',
    cities: ['Lisboa', 'Oporto', 'Algarve', 'Madeira', 'Azores', 'Sintra', 'Évora', 'Coímbra', 'Braga', 'Faro'],
    currency: 'EUR',
    climate: 'Mediterráneo, 10-30°C',
    language: 'Portugués',
  ),
  'Australia': CountryData(
    name: 'Australia',
    cities: ['Sídney', 'Melbourne', 'Brisbane', 'Perth', 'Adelaida', 'Gold Coast', 'Cairns', 'Canberra', 'Hobart', 'Darwin'],
    currency: 'AUD',
    climate: 'Variado, 10-40°C',
    language: 'Inglés',
  ),
  'Nueva Zelanda': CountryData(
    name: 'Nueva Zelanda',
    cities: ['Auckland', 'Wellington', 'Queenstown', 'Christchurch', 'Rotorua', 'Dunedin', 'Taupo', 'Nelson', 'Napier', 'Hamilton'],
    currency: 'NZD',
    climate: 'Templado, 5-25°C',
    language: 'Inglés',
  ),
  'Canadá': CountryData(
    name: 'Canadá',
    cities: ['Toronto', 'Vancouver', 'Montreal', 'Quebec', 'Calgary', 'Ottawa', 'Edmonton', 'Winnipeg', 'Victoria', 'Niagara Falls'],
    currency: 'CAD',
    climate: 'Variado, -30-30°C',
    language: 'Inglés, Francés',
  ),
};

// Mantener compatibilidad con código anterior
const Map<String, List<String>> countriesWithCities = {
  'Colombia': ['Bogotá', 'Medellín', 'Cali', 'Cartagena', 'Barranquilla', 'Santa Marta', 'Pereira', 'Bucaramanga', 'Cúcuta', 'Manizales'],
  'México': ['Ciudad de México', 'Guadalajara', 'Monterrey', 'Cancún', 'Playa del Carmen', 'Puerto Vallarta', 'Los Cabos', 'Mérida', 'Oaxaca', 'Puebla'],
  'Estados Unidos': ['Nueva York', 'Los Ángeles', 'Miami', 'Las Vegas', 'Orlando', 'San Francisco', 'Chicago', 'Boston', 'Seattle', 'Washington D.C.'],
  'España': ['Madrid', 'Barcelona', 'Sevilla', 'Valencia', 'Málaga', 'Bilbao', 'Granada', 'Palma de Mallorca', 'Ibiza', 'San Sebastián'],
  'Francia': ['París', 'Niza', 'Lyon', 'Marsella', 'Burdeos', 'Toulouse', 'Estrasburgo', 'Cannes', 'Montpellier', 'Nantes'],
  'Italia': ['Roma', 'Milán', 'Venecia', 'Florencia', 'Nápoles', 'Turín', 'Bolonia', 'Verona', 'Pisa', 'Génova'],
  'Reino Unido': ['Londres', 'Edimburgo', 'Manchester', 'Liverpool', 'Birmingham', 'Glasgow', 'Oxford', 'Cambridge', 'Brighton', 'Bristol'],
  'Alemania': ['Berlín', 'Múnich', 'Frankfurt', 'Hamburgo', 'Colonia', 'Stuttgart', 'Düsseldorf', 'Dortmund', 'Essen', 'Leipzig'],
  'Brasil': ['Río de Janeiro', 'São Paulo', 'Brasilia', 'Salvador', 'Fortaleza', 'Recife', 'Manaos', 'Florianópolis', 'Foz do Iguaçu', 'Búzios'],
  'Argentina': ['Buenos Aires', 'Mendoza', 'Córdoba', 'Bariloche', 'Ushuaia', 'Salta', 'Rosario', 'Mar del Plata', 'El Calafate', 'Iguazú'],
  'Perú': ['Lima', 'Cusco', 'Arequipa', 'Puno', 'Trujillo', 'Iquitos', 'Paracas', 'Máncora', 'Huaraz', 'Nazca'],
  'Chile': ['Santiago', 'Valparaíso', 'Viña del Mar', 'Puerto Varas', 'Punta Arenas', 'La Serena', 'Antofagasta', 'Concepción', 'Arica', 'Iquique'],
  'Ecuador': ['Quito', 'Guayaquil', 'Cuenca', 'Galápagos', 'Montañita', 'Baños', 'Manta', 'Salinas', 'Otavalo', 'Loja'],
  'Panamá': ['Ciudad de Panamá', 'Bocas del Toro', 'Boquete', 'San Blas', 'Colón', 'David', 'Chitré', 'Pedasí', 'El Valle', 'Portobelo'],
  'Costa Rica': ['San José', 'Manuel Antonio', 'Tamarindo', 'La Fortuna', 'Puerto Viejo', 'Monteverde', 'Jacó', 'Uvita', 'Nosara', 'Guanacaste'],
  'República Dominicana': ['Punta Cana', 'Santo Domingo', 'Puerto Plata', 'La Romana', 'Samaná', 'Bávaro', 'Cabarete', 'Juan Dolio', 'Bayahíbe', 'Las Terrenas'],
  'Cuba': ['La Habana', 'Varadero', 'Trinidad', 'Santiago de Cuba', 'Viñales', 'Cienfuegos', 'Santa Clara', 'Cayo Coco', 'Holguín', 'Camagüey'],
  'Japón': ['Tokio', 'Kioto', 'Osaka', 'Hiroshima', 'Nara', 'Yokohama', 'Sapporo', 'Fukuoka', 'Nagoya', 'Okinawa'],
  'China': ['Pekín', 'Shanghái', 'Hong Kong', 'Xi\'an', 'Guilin', 'Chengdu', 'Hangzhou', 'Suzhou', 'Guangzhou', 'Shenzhen'],
  'Tailandia': ['Bangkok', 'Phuket', 'Chiang Mai', 'Pattaya', 'Krabi', 'Koh Samui', 'Ayutthaya', 'Hua Hin', 'Koh Phi Phi', 'Chiang Rai'],
  'Emiratos Árabes Unidos': ['Dubái', 'Abu Dhabi', 'Sharjah', 'Ras Al Khaimah', 'Fujairah', 'Ajman', 'Al Ain', 'Umm Al Quwain'],
  'Turquía': ['Estambul', 'Ankara', 'Antalya', 'Capadocia', 'Bodrum', 'Esmirna', 'Mármaris', 'Pamukkale', 'Éfeso', 'Fethiye'],
  'Grecia': ['Atenas', 'Santorini', 'Mykonos', 'Creta', 'Rodas', 'Corfú', 'Tesalónica', 'Zakynthos', 'Naxos', 'Paros'],
  'Portugal': ['Lisboa', 'Oporto', 'Algarve', 'Madeira', 'Azores', 'Sintra', 'Évora', 'Coímbra', 'Braga', 'Faro'],
  'Australia': ['Sídney', 'Melbourne', 'Brisbane', 'Perth', 'Adelaida', 'Gold Coast', 'Cairns', 'Canberra', 'Hobart', 'Darwin'],
  'Nueva Zelanda': ['Auckland', 'Wellington', 'Queenstown', 'Christchurch', 'Rotorua', 'Dunedin', 'Taupo', 'Nelson', 'Napier', 'Hamilton'],
  'Canadá': ['Toronto', 'Vancouver', 'Montreal', 'Quebec', 'Calgary', 'Ottawa', 'Edmonton', 'Winnipeg', 'Victoria', 'Niagara Falls'],
};

List<String> getCountries() {
  return countriesData.keys.toList()..sort();
}

List<String> getCitiesForCountry(String country) {
  return countriesData[country]?.cities ?? [];
}

String? getCurrencyForCountry(String country) {
  return countriesData[country]?.currency;
}

String? getClimateForCountry(String country) {
  return countriesData[country]?.climate;
}

String? getLanguageForCountry(String country) {
  return countriesData[country]?.language;
}
