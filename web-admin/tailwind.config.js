/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,ts,jsx,tsx}'],
  theme: {
    extend: {
      colors: {
        brand: {
          blue: '#1B4F72',
          amber: '#F39C12',
        }
      }
    }
  },
  plugins: []
}
