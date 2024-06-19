import { defineConfig } from 'vite';
import cp from 'vite-plugin-cp';

// https://vitejs.dev/config/
export default defineConfig({
    plugins: [
        cp({
            targets: [
                // Copy all icons to the assets/icons directory
                {
                    src: 'dist/icons',
                    dest: '../Sources/WebsiteGen/Resources/assets/icons',
                    flatten: false
                },
                // Copy public image assets from the output directory into the assets root
                {
                    src: 'dist/*.{svg,png,jpg,gif}',
                    dest: '../Sources/WebsiteGen/Resources/assets'
                },
                // Copy generated output js and css bundle into the assets root
                {
                    src: 'dist/assets/*',
                    dest: '../Sources/WebsiteGen/Resources/assets',
                    rename: name => {
                        let extension = name.split(".").pop()
                        return 'app.' + extension
                    }
                }
            ]
        })
    ],
});