#!/usr/bin/env node

/**
 * 新しいGutenbergブロックを作成するスクリプト
 *
 * 使用方法:
 *   npm run create-block [ブロック名]
 *   または
 *   node scripts/create-block.js [ブロック名]
 *
 * 引数がない場合は対話式で入力を受け付けます
 */

const fs = require('fs');
const path = require('path');
const readline = require('readline');

const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
});

function question(query) {
    return new Promise(resolve => rl.question(query, resolve));
}

function toKebabCase(str) {
    return str
        .replace(/([a-z])([A-Z])/g, '$1-$2')
        .replace(/[\s_]+/g, '-')
        .toLowerCase();
}

function toPascalCase(str) {
    return str
        .split(/[-_\s]+/)
        .map(word => word.charAt(0).toUpperCase() + word.slice(1).toLowerCase())
        .join('');
}

function createBlock(blockName) {
    const kebabName = toKebabCase(blockName);
    const pascalName = toPascalCase(blockName);
    const blockDir = path.join(__dirname, '../blocks', kebabName);
    const srcDir = path.join(blockDir, 'src');
    const buildDir = path.join(blockDir, 'build');

    // ディレクトリが既に存在する場合はエラー
    if (fs.existsSync(blockDir)) {
        console.error(`❌ エラー: ブロック "${kebabName}" は既に存在します`);
        process.exit(1);
    }

    // ディレクトリを作成
    fs.mkdirSync(blockDir, { recursive: true });
    fs.mkdirSync(srcDir, { recursive: true });
    fs.mkdirSync(buildDir, { recursive: true });

    // block.json
    const blockJson = {
        "$schema": "https://schemas.wp.org/trunk/block.json",
        "apiVersion": 2,
        "name": `nya/${kebabName}`,
        "title": pascalName,
        "category": "text",
        "icon": "editor-paragraph",
        "description": `A ${kebabName} block`,
        "attributes": {
            "content": {
                "type": "string",
                "default": ""
            },
            "number": {
                "type": "number",
                "default": 0
            },
            "imageId": {
                "type": "number",
                "default": 0
            },
            "imageUrl": {
                "type": "string",
                "default": ""
            },
            "imageAlt": {
                "type": "string",
                "default": ""
            },
            "url": {
                "type": "string",
                "default": ""
            },
            "urlText": {
                "type": "string",
                "default": ""
            },
            "repeat": {
                "type": "array",
                "default": []
            }
        },
        "supports": {
            "html": false
        },
        "editorScript": "file:./build/index.js",
        "render": "file:./render.php"
    };

    fs.writeFileSync(
        path.join(blockDir, 'block.json'),
        JSON.stringify(blockJson, null, 2) + '\n'
    );

    // src/index.js
    const indexJs = `/**
 * WordPress dependencies
 */
import { registerBlockType } from '@wordpress/blocks';

/**
 * Internal dependencies
 */
import metadata from '../block.json';
import edit from './edit';

const { name } = metadata;

registerBlockType(name, {
	...metadata,
	edit,
	save: () => null, // 動的ブロックなのでsaveはnull
});
`;

    fs.writeFileSync(path.join(srcDir, 'index.js'), indexJs);

    // src/edit.js
    const editJs = `/**
 * WordPress dependencies
 */
import { useBlockProps, RichText, MediaUpload, MediaUploadCheck } from '@wordpress/block-editor';
import { Button, TextControl, PanelBody } from '@wordpress/components';
import { __ } from '@wordpress/i18n';

export default function Edit({ attributes, setAttributes }) {
	const blockProps = useBlockProps();
	const {
		content = '',
		number = 0,
		imageId = 0,
		imageUrl = '',
		imageAlt = '',
		url = '',
		urlText = '',
		repeat = []
	} = attributes;

	const onChangeContent = (value) => {
		setAttributes({ content: value });
	};

	const onChangeNumber = (value) => {
		setAttributes({ number: parseInt(value, 10) || 0 });
	};

	const onSelectImage = (media) => {
		setAttributes({
			imageId: media.id,
			imageUrl: media.url,
			imageAlt: media.alt || '',
		});
	};

	const onRemoveImage = () => {
		setAttributes({
			imageId: 0,
			imageUrl: '',
			imageAlt: '',
		});
	};

	const onChangeUrl = (value) => {
		setAttributes({ url: value });
	};

	const onChangeUrlText = (value) => {
		setAttributes({ urlText: value });
	};

	return (
		<div {...blockProps}>
			<PanelBody title={__('コンテンツ設定', 'nyardpress')} initialOpen={true}>
				<RichText
					tagName="p"
					value={content || ''}
					onChange={onChangeContent}
					placeholder={__('Enter content...', 'nyardpress')}
				/>

				<TextControl
					label={__('数字', 'nyardpress')}
					type="number"
					value={number}
					onChange={onChangeNumber}
					help={__('数値を入力してください', 'nyardpress')}
					__next40pxDefaultSize
					__nextHasNoMarginBottom
				/>

				<MediaUploadCheck>
					<MediaUpload
						onSelect={onSelectImage}
						allowedTypes={['image']}
						value={imageId}
						render={({ open }) => (
							<div>
								{imageUrl ? (
									<div>
										<img src={imageUrl} alt={imageAlt} style={{ maxWidth: '100%', height: 'auto' }} />
										<Button onClick={onRemoveImage} isDestructive>
											{__('画像を削除', 'nyardpress')}
										</Button>
									</div>
								) : (
									<Button onClick={open} variant="primary">
										{__('画像を選択', 'nyardpress')}
									</Button>
								)}
							</div>
						)}
					/>
				</MediaUploadCheck>

				<TextControl
					label={__('URL', 'nyardpress')}
					value={url}
					onChange={onChangeUrl}
					placeholder={__('https://example.com', 'nyardpress')}
					__next40pxDefaultSize
					__nextHasNoMarginBottom
				/>

				<TextControl
					label={__('URLテキスト', 'nyardpress')}
					value={urlText}
					onChange={onChangeUrlText}
					placeholder={__('リンクテキスト', 'nyardpress')}
					__next40pxDefaultSize
					__nextHasNoMarginBottom
				/>
			</PanelBody>
		</div>
	);
}
`;

    fs.writeFileSync(path.join(srcDir, 'edit.js'), editJs);

    // render.php
    const renderPhp = `<?php
/**
 * Render callback for nya/${kebabName}
 *
 * @param array $attributes Block attributes
 * @param string $content Block content (inner blocks)
 * @param WP_Block $block Block instance
 */

// このファイルが直接アクセスされた場合は終了
if (!defined('ABSPATH')) {
    exit;
}

// ユーティリティ関数を読み込む（nya_twig関数を使用）
if (!function_exists('nya_twig')) {
    // site-coreのutilities/nya_twig.phpを読み込む
    $twig_utility = dirname(dirname(__DIR__)) . '/utilities/nya_twig.php';
    if (file_exists($twig_utility)) {
        require_once $twig_utility;
    }
}

// 動的ブロックの場合、attributesに直接値が保存される
// $attributesは配列またはオブジェクトの可能性がある
$context = array();
if (is_array($attributes)) {
    $context = $attributes;
} elseif (is_object($attributes)) {
    $context = (array) $attributes;
}

// ブロック名をコンテキストに追加
$context['block_name'] = 'nya-${kebabName}';
$context['block_class'] = 'wp-block-nya-${kebabName}';

// Twig環境を取得
$block_dir = __DIR__;
$twig = nya_twig($block_dir);

if ($twig) {
    // Twigテンプレートをレンダリング
    try {
        echo $twig->render('view.twig', $context);
    } catch (Exception $e) {
        error_log('Twig render error: ' . $e->getMessage());
        echo '<div class="wp-block-nya-${kebabName}"><p>Template rendering error.</p></div>';
    }
}
`;

    fs.writeFileSync(path.join(blockDir, 'render.php'), renderPhp);

    // views/block.twig
    const blockTwig = `{# ブロック: ${pascalName} #}
<div class="{{ block_class }}">
	{% if content %}
		<div class="{{ block_class }}__content">
			{{ content|raw }}
		</div>
	{% endif %}

	{% if number > 0 %}
		<div class="{{ block_class }}__number">
			<p>数字: {{ number }}</p>
		</div>
	{% endif %}

	{% if imageUrl %}
		<div class="{{ block_class }}__image">
			<img src="{{ imageUrl }}" alt="{{ imageAlt }}" />
		</div>
	{% endif %}

	{% if url %}
		<div class="{{ block_class }}__link">
			<a href="{{ url }}">{{ urlText ?: url }}</a>
		</div>
	{% endif %}

	{% if repeat %}
		<div class="{{ block_class }}__repeat">
			{% for item in repeat %}
				<div class="{{ block_class }}__repeat-item">
					{# 繰り返し項目の内容をここに記述 #}
				</div>
			{% endfor %}
		</div>
	{% endif %}
</div>
`;

    fs.writeFileSync(path.join(blockDir, 'view.twig'), blockTwig);

    console.log(`✅ ブロック "${kebabName}" を作成しました`);
    console.log(`📁 ディレクトリ: ${blockDir}`);
    console.log(`\n次のステップ:`);
    console.log(`1. npm run build でビルド`);
    console.log(`2. WordPress管理画面でブロックを確認`);
}

async function main() {
    let blockName = process.argv[2];

    if (!blockName) {
        console.log('新しいGutenbergブロックを作成します\n');
        blockName = await question('ブロック名を入力してください: ');

        if (!blockName || blockName.trim() === '') {
            console.error('❌ エラー: ブロック名が入力されていません');
            rl.close();
            process.exit(1);
        }
    }

    blockName = blockName.trim();
    createBlock(blockName);
    rl.close();
}

main().catch(error => {
    console.error('❌ エラー:', error);
    rl.close();
    process.exit(1);
});

