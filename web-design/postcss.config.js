export default {
  plugins: {
    '@csstools/postcss-sass': {},
    'tailwindcss': {},
    'autoprefixer': {},
    'postcss-import': {},
    'postcss-mixins': {},
    'postcss-nested': {},
    '@fullhuman/postcss-purgecss': {
      content: ['./src/js/**/*.ts', './**/*.html']
    }
  },
  module: true,
  url: false,
}
