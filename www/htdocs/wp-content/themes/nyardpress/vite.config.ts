import { defineConfig } from 'vite';
// TODO: Rolldownが正式リリースされたら、以下のように変更
// import { rolldown } from 'vite-plugin-rolldown';
import { resolve } from 'path';
import { config } from 'dotenv';

export default defineConfig(({ mode }) => {
  const isProduction = mode === 'production';
  const themeDir = __dirname;

  // テーマ側の.envファイルから環境変数を読み込む
  const envPath = resolve(themeDir, '.env');
  config({ path: envPath });
  const vitePort = parseInt(process.env.VITE_PORT || '3000', 10);

  return {
    // TODO: Rolldownが正式リリースされたら、以下のプラグインを有効化
    // plugins: [
    //   rolldown({
    //     // Rolldownの設定
    //   })
    // ],
    root: resolve(themeDir, 'src'),
    resolve: {
      // テーマディレクトリ内のnode_modulesのみを使用
      dedupe: [],
      // Litのビルドを選択: 開発モードでは'development'、本番では'production'（デフォルト）
      conditions: isProduction ? ['production', 'default'] : ['development', 'default'],
    },
    esbuild: {
      loader: 'ts',
      include: /\.ts$/,
    },
    build: {
      outDir: resolve(themeDir, 'assets'),
      emptyOutDir: true, // ビルド時にassetsディレクトリをクリア
      manifest: true,
      manifestFileName: '.vite/manifest.json',
      rollupOptions: {
        input: {
          // rootがsrcに設定されているため、rootからの相対パスで指定
          // または絶対パスで指定
          main: resolve(themeDir, 'src/js/main.ts'),
          style: resolve(themeDir, 'src/css/style.css'),
        },
        output: {
          entryFileNames: 'js/[name].js',
          chunkFileNames: 'js/[name]-[hash].js',
          assetFileNames: (assetInfo) => {
            if (assetInfo.name?.endsWith('.css')) {
              return 'css/style.css';
            }
            return 'assets/[name]-[hash][extname]';
          },
        },
      },
      sourcemap: !isProduction,
      minify: isProduction ? 'esbuild' : false,
    },
    server: {
      host: '0.0.0.0', // Dockerコンテナ内からアクセス可能にする
      port: vitePort,
      strictPort: true,
      cors: true,
      hmr: {
        // HMRはブラウザからlocalhost経由でアクセス
        // WordPressは8080でアクセスしているが、Viteは3000で動いている
        // hostとclientPortを明示的に指定することで、ブラウザが正しいポートに接続できる
        host: 'localhost', // ブラウザから見たホスト名
        port: vitePort, // WebSocketサーバーのポート（Viteサーバーと同じ）
        clientPort: vitePort, // ブラウザからアクセスするポート（3000）
        protocol: 'ws', // WebSocketプロトコル
      },
      watch: {
        // ファイル変更の監視設定
        usePolling: false,
        interval: 100,
      },
    },
  };
});

