class ShowPayload {
  static ShowPayload fromJson(Map<String, dynamic> json) {
    return ShowPayload(
      success: json["success"],
      show: Show.fromJson(json["show"]),
    );
  }

  const ShowPayload({
    required this.success,
    required this.show,
  });

  final bool success;
  final Show show;
}

class Show {
  static Show fromJson(Map<String, dynamic> json) {
    return Show(
      id: json["id"],
      created: json["created"],
      lastFeedGeneration: json["last_feed_generation"],
      status: json["status"],
      title: json["title"],
      artwork: json["artwork"],
      link: json["link"],
      description: json["description"],
      categories: json["categories"],
      googleCategories: json["google_categories"],
      order: json["order"],
      summary: json["summary"],
      author: json["author"],
      subtitle: json["subtitle"],
      copyright: json["copyright"],
      name: json["name"],
      itunesEmail: json["itunes_email"],
      explicit: json["explicit"],
      limit: json["limit"],
      type: json["type"],
      keywords: json["keywords"],
      donationLink: json["donation_link"],
      donationText: json["donation_text"],
      siteId: json["site_id"],
      filename: json["file_name"],
      season: json["season"],
      timeZone: json["time_zone"],
      import: json["import"],
      failedImport: json["failed_import"],
      importedFrom: json["imported_from"],
      thirdPartyAnalytics: json["third_party_analytics"],
      prefixes: json["prefixes"],
      spotifyUri: json["spotify_uri"],
      spotifyStatus: json["spotify_status"],
      defaultTime: json["default_time"],
      importedRssFeed: json["imported_rss_feed"],
      completeShow: json["complete_show"],
      language: json["language"],
      pwSiteId: json["pw_site_id"],
      pwClientId: json["pw_client_id"],
      transparencyMode: json["transparencyMode"],
      audienceAvatar: json["audience_avatar"],
      captivateSyncUrl: json["captivate_sync_url"],
      amazonSubmitted: json["amazon_submitted"],
      countryOfOrigin: json["country_of_origin"],
      gaanaSubmitted: json["gaana_submitted"],
      jiosaavnSubmitted: json["jiosaavn_submitted"],
      podcastIndexSubmitted: json["podcast_index_submitted"],
      playerFmSubmitted: json["player_fm_submitted"],
      importCancelKey: json["import_cancel_key"],
      private: json["private"],
      deezerSubmitted: json["deezer_submitted"],
      importErrors: json["import_errors"],
      googleBlock: json["google_block"],
      itunesBlock: json["itunes_block"],
      defaultPreRollMediaId: json["default_pre_roll_media_id"],
      defaultPostRollMediaId: json["default_post_roll_media_id"],
      featurePreview: json["feature_preview"],
      defaultShownotesTemplate: json["default_shownotes_template"],
      amieBulkEditCount: json["amie_bulk_edit_count"],
      showLink: json["show_link"],
      enabledSite: json["enabled_site"],
      customDomain: json["custom_domain"],
      syncEnabled: json["sync_enabled"],
      syncWebhook: json["sync_webhook"],
      networkId: json["network_id"],
    );
  }

  const Show({
    required this.id,
    required this.created,
    required this.lastFeedGeneration,
    required this.status,
    required this.title,
    required this.artwork,
    required this.link,
    required this.description,
    required this.categories,
    required this.googleCategories,
    required this.order,
    required this.summary,
    required this.author,
    required this.subtitle,
    required this.copyright,
    required this.name,
    required this.itunesEmail,
    required this.explicit,
    required this.limit,
    required this.type,
    required this.keywords,
    required this.donationLink,
    required this.donationText,
    required this.siteId,
    required this.filename,
    required this.season,
    required this.timeZone,
    required this.import,
    required this.failedImport,
    required this.importedFrom,
    required this.thirdPartyAnalytics,
    required this.prefixes,
    required this.spotifyUri,
    required this.spotifyStatus,
    required this.defaultTime,
    required this.importedRssFeed,
    required this.completeShow,
    required this.language,
    required this.pwSiteId,
    required this.pwClientId,
    required this.transparencyMode,
    required this.audienceAvatar,
    required this.captivateSyncUrl,
    required this.amazonSubmitted,
    required this.countryOfOrigin,
    required this.gaanaSubmitted,
    required this.jiosaavnSubmitted,
    required this.podcastIndexSubmitted,
    required this.playerFmSubmitted,
    required this.importCancelKey,
    required this.private,
    required this.deezerSubmitted,
    required this.importErrors,
    required this.googleBlock,
    required this.itunesBlock,
    required this.defaultPreRollMediaId,
    required this.defaultPostRollMediaId,
    required this.featurePreview,
    required this.defaultShownotesTemplate,
    required this.amieBulkEditCount,
    required this.showLink,
    required this.enabledSite,
    required this.customDomain,
    required this.syncEnabled,
    required this.syncWebhook,
    required this.networkId,
  });

  final String id;
  final String created;
  final String lastFeedGeneration;
  final String status;
  final String? title;
  final String artwork;
  final String? link;
  final String description;
  final String categories;
  final List<String>? googleCategories;
  final String order;
  final String summary;
  final String author;
  final String subtitle;
  final String? copyright;
  final String name;
  final String? itunesEmail;
  final String explicit;
  final int limit;
  final String type;
  final String? keywords;
  final String? donationLink;
  final String? donationText;
  final String? siteId;
  final String? filename;
  final String? season;
  final String timeZone;
  final String import;
  final int failedImport;
  final String? importedFrom;
  final String? thirdPartyAnalytics;
  final List<String>? prefixes;
  final String? spotifyUri;
  final int? spotifyStatus;
  final String defaultTime;
  final String? importedRssFeed;
  final String? completeShow;
  final String language;
  final String? pwSiteId;
  final String? pwClientId;
  final int? transparencyMode;
  final String? audienceAvatar;
  final String? captivateSyncUrl;
  final String? amazonSubmitted;
  final String? countryOfOrigin;
  final String? gaanaSubmitted;
  final String? jiosaavnSubmitted;
  final String? podcastIndexSubmitted;
  final String? playerFmSubmitted;
  final String? importCancelKey;
  final int private;
  final String? deezerSubmitted;
  final String? importErrors;
  final String? googleBlock;
  final String? itunesBlock;
  final String? defaultPreRollMediaId;
  final String? defaultPostRollMediaId;
  final int? featurePreview;
  final String? defaultShownotesTemplate;
  final int? amieBulkEditCount;
  final String? showLink;
  final int? enabledSite;
  final String? customDomain;
  final int? syncEnabled;
  final String? syncWebhook;
  final String? networkId;
}
