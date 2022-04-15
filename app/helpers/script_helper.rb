# rubocop:disable Rails/HelperInstanceVariable
module ScriptHelper
  def javascript_include_tag_without_preload(...)
    without_preload_links_header { javascript_include_tag(...) }
  end

  def javascript_packs_tag_once(*names, prepend: false)
    @scripts ||= []
    if prepend
      @scripts = names | @scripts
    else
      @scripts |= names
    end
    nil
  end

  alias_method :enqueue_component_scripts, :javascript_packs_tag_once

  def render_javascript_pack_once_tags(*names)
    javascript_packs_tag_once(*names) if names.present?
    if @scripts && (sources = AssetSources.get_sources(*@scripts)).present?
      safe_join(
        [
          javascript_assets_tag(*@scripts),
          javascript_polyfill_pack_tag,
          javascript_include_tag(*sources, crossorigin: local_crossorigin_sources? ? true : nil),
        ],
      )
    end
  end

  private

  def local_crossorigin_sources?
    Rails.env.development? && ENV['WEBPACK_PORT'].present?
  end

  def javascript_assets_tag(*names)
    assets = AssetSources.get_assets(*names)
    if assets.present?
      asset_map = assets.index_with { |path| asset_path(path) }
      content_tag(
        :script,
        asset_map.to_json,
        { type: 'application/json', data: { asset_map: '' } },
        false,
      )
    end
  end

  def javascript_polyfill_pack_tag
    javascript_include_tag_without_preload(
      *AssetSources.get_sources('polyfill'),
      nomodule: '',
      crossorigin: local_crossorigin_sources? ? true : nil,
    )
  end

  def without_preload_links_header
    original_preload_links_header = ActionView::Helpers::AssetTagHelper.preload_links_header
    ActionView::Helpers::AssetTagHelper.preload_links_header = false
    result = yield
    ActionView::Helpers::AssetTagHelper.preload_links_header = original_preload_links_header
    result
  end
end
# rubocop:enable Rails/HelperInstanceVariable
