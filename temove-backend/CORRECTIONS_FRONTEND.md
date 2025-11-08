# 🔧 Corrections nécessaires pour le Frontend

## 📍 Problème identifié

Le frontend React Native (`allo-dakar-frontend`) utilise une URL d'API incorrecte :
- **URL actuelle** : `http://127.0.0.1:5000/api`
- **URL correcte** : `http://127.0.0.1:5000/api/v1`

De plus, les endpoints utilisés (`/auth/request-otp` et `/auth/verify-otp`) n'existent pas dans le backend. Le backend utilise `/auth/register` et `/auth/login`.

## ✅ Corrections à apporter

### 1. Mettre à jour `src/api/api.ts`

Remplacer le contenu actuel par :

```typescript
import axios from 'axios';

// Configuration de l'URL de base de l'API
// Pour Android Emulator, utiliser: 'http://10.0.2.2:5000/api/v1'
// Pour iOS Simulator ou Web, utiliser: 'http://localhost:5000/api/v1'
// Pour appareil physique, utiliser l'IP de votre PC: 'http://192.168.1.100:5000/api/v1'
const API_BASE = 'http://127.0.0.1:5000/api/v1';

// Créer une instance axios avec configuration par défaut
const apiClient = axios.create({
  baseURL: API_BASE,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Intercepteur pour ajouter le token JWT aux requêtes
apiClient.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('access_token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Intercepteur pour gérer les erreurs de token expiré
apiClient.interceptors.response.use(
  (response) => response,
  async (error) => {
    const originalRequest = error.config;
    
    if (error.response?.status === 401 && !originalRequest._retry) {
      originalRequest._retry = true;
      
      // Essayer de rafraîchir le token
      const refreshToken = localStorage.getItem('refresh_token');
      if (refreshToken) {
        try {
          const response = await axios.post(`${API_BASE}/auth/refresh`, {}, {
            headers: { Authorization: `Bearer ${refreshToken}` }
          });
          const { access_token } = response.data;
          localStorage.setItem('access_token', access_token);
          originalRequest.headers.Authorization = `Bearer ${access_token}`;
          return apiClient(originalRequest);
        } catch (refreshError) {
          // Token de rafraîchissement invalide, déconnecter l'utilisateur
          localStorage.removeItem('access_token');
          localStorage.removeItem('refresh_token');
          // Rediriger vers la page de connexion
          return Promise.reject(refreshError);
        }
      }
    }
    
    return Promise.reject(error);
  }
);

// ===== AUTHENTIFICATION =====

export const register = (email: string, password: string, fullName: string, phone?: string, referralCode?: string) =>
  apiClient.post('/auth/register', { email, password, full_name: fullName, phone, referral_code: referralCode });

export const login = (email: string, password: string) =>
  apiClient.post('/auth/login', { email, password });

export const getCurrentUser = () =>
  apiClient.get('/auth/me');

export const refreshToken = (refreshToken: string) =>
  apiClient.post('/auth/refresh', {}, {
    headers: { Authorization: `Bearer ${refreshToken}` }
  });

// ===== RIDES (COURSES) =====

export const estimateRide = (data: {
  pickup_latitude: number;
  pickup_longitude: number;
  dropoff_latitude: number;
  dropoff_longitude: number;
  ride_mode: string;
  promo_code?: string;
}) =>
  apiClient.post('/rides/estimate', data);

export const requestRide = (data: {
  pickup_latitude: number;
  pickup_longitude: number;
  dropoff_latitude: number;
  dropoff_longitude: number;
  ride_mode: string;
  promo_code?: string;
  payment_method?: string;
}) =>
  apiClient.post('/rides', data);

export const getRide = (rideId: number) =>
  apiClient.get(`/rides/${rideId}`);

export const getUserRides = () =>
  apiClient.get('/rides');

export const cancelRide = (rideId: number) =>
  apiClient.post(`/rides/${rideId}/cancel`);

// ===== PROMO CODES =====

export const validatePromoCode = (code: string) =>
  apiClient.post('/promo/validate', { code });

export const listPromoCodes = () =>
  apiClient.get('/promo');

// ===== LOYALTY (FIDÉLITÉ) =====

export const getLoyaltyPoints = () =>
  apiClient.get('/loyalty/points');

export const getLoyaltyHistory = () =>
  apiClient.get('/loyalty/history');

// ===== USER PROFILE =====

export const getUserProfile = () =>
  apiClient.get('/users/profile');

export const updateUserProfile = (data: {
  full_name?: string;
  phone?: string;
}) =>
  apiClient.put('/users/profile', data);

// ===== RATINGS =====

export const submitRating = (rideId: number, rating: number, comment?: string) =>
  apiClient.post('/ratings', { ride_id: rideId, rating, comment });

// ===== LANDMARKS (POINTS D'INTÉRÊT) =====

export const listLandmarks = (type?: string) =>
  apiClient.get('/landmarks', { params: { type } });

export const getLandmarkTypes = () =>
  apiClient.get('/landmarks/types');

export default apiClient;
```

### 2. Mettre à jour les écrans qui utilisent l'API

#### Pour `LoginScreen.tsx` (si existant)

Si vous avez un écran de connexion qui utilise `requestOTP` et `verifyOTP`, il faut le modifier pour utiliser `register` et `login` à la place.

Exemple :

```typescript
// Avant
import { requestOTP, verifyOTP } from '../api/api';

// Après
import { register, login } from '../api/api';

// Pour l'inscription
const handleRegister = async () => {
  try {
    const response = await register(email, password, fullName, phone);
    // Sauvegarder les tokens
    localStorage.setItem('access_token', response.data.access_token);
    localStorage.setItem('refresh_token', response.data.refresh_token);
    // Naviguer vers l'écran principal
  } catch (error) {
    console.error('Erreur d\'inscription:', error);
  }
};

// Pour la connexion
const handleLogin = async () => {
  try {
    const response = await login(email, password);
    // Sauvegarder les tokens
    localStorage.setItem('access_token', response.data.access_token);
    localStorage.setItem('refresh_token', response.data.refresh_token);
    // Naviguer vers l'écran principal
  } catch (error) {
    console.error('Erreur de connexion:', error);
  }
};
```

### 3. Note importante pour React Native

⚠️ **Attention** : React Native n'utilise pas `localStorage`. Il faut utiliser `AsyncStorage` à la place :

```typescript
import AsyncStorage from '@react-native-async-storage/async-storage';

// Remplacer localStorage.setItem par :
await AsyncStorage.setItem('access_token', token);

// Remplacer localStorage.getItem par :
const token = await AsyncStorage.getItem('access_token');

// Remplacer localStorage.removeItem par :
await AsyncStorage.removeItem('access_token');
```

## 📝 Endpoints disponibles dans le backend

### Authentification
- `POST /api/v1/auth/register` - Inscription
- `POST /api/v1/auth/login` - Connexion
- `POST /api/v1/auth/refresh` - Rafraîchir le token
- `GET /api/v1/auth/me` - Obtenir l'utilisateur connecté

### Courses (Rides)
- `POST /api/v1/rides/estimate` - Estimer le prix
- `POST /api/v1/rides` - Demander une course
- `GET /api/v1/rides/:id` - Obtenir une course
- `GET /api/v1/rides` - Liste des courses de l'utilisateur
- `POST /api/v1/rides/:id/cancel` - Annuler une course

### Codes Promo
- `POST /api/v1/promo/validate` - Valider un code promo
- `GET /api/v1/promo` - Liste des codes promo

### Fidélité
- `GET /api/v1/loyalty/points` - Points de fidélité
- `GET /api/v1/loyalty/history` - Historique de fidélité

### Utilisateurs
- `GET /api/v1/users/profile` - Profil utilisateur
- `PUT /api/v1/users/profile` - Mettre à jour le profil

### Notes
- `POST /api/v1/ratings` - Soumettre une note

### Points d'intérêt
- `GET /api/v1/landmarks` - Liste des points d'intérêt
- `GET /api/v1/landmarks/types` - Types de points d'intérêt

## 🔗 URLs selon l'environnement

- **Web (localhost)** : `http://localhost:5000/api/v1`
- **Android Emulator** : `http://10.0.2.2:5000/api/v1`
- **iOS Simulator** : `http://localhost:5000/api/v1`
- **Appareil physique** : `http://[VOTRE_IP]:5000/api/v1` (ex: `http://192.168.1.100:5000/api/v1`)

## ✅ Vérification

Après avoir appliqué ces corrections :

1. Vérifier que le backend est lancé : `http://localhost:5000/health`
2. Tester l'inscription : `POST http://localhost:5000/api/v1/auth/register`
3. Tester la connexion : `POST http://localhost:5000/api/v1/auth/login`
4. Vérifier que les tokens JWT sont bien sauvegardés
5. Tester une requête authentifiée : `GET http://localhost:5000/api/v1/auth/me`

