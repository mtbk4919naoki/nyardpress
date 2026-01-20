/**
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
