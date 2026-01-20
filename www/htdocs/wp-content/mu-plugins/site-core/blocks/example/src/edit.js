/**
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
