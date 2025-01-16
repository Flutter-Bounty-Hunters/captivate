class EpisodesPayload {
  static EpisodesPayload fromJson(Map<String, dynamic> json) {
    return EpisodesPayload(
      count: json["count"],
      episodes: [
        for (final episodeJson in json["episodes"]) //
          Episode.fromJson(episodeJson),
      ],
    );
  }

  const EpisodesPayload({
    required this.count,
    required this.episodes,
  });

  final int count;
  final List<Episode> episodes;
}

class EpisodePayload {
  static EpisodePayload fromJson(Map<String, dynamic> json) {
    return EpisodePayload(
      episode: Episode.fromJson(json["episode"]),
    );
  }

  const EpisodePayload({
    required this.episode,
  });

  final Episode episode;
}

class Episode {
  static Episode fromJson(Map<String, dynamic> json) {
    return Episode(
      showId: json['shows_id'],
      id: json['id'],
      title: json['title'],
      iTunesTitle: json['itunes_title'],
      mediaId: json['media_id'],
      date: json['date'],
      status: json['status'],
      showNotes: json['shownotes'],
      summary: json['summary'],
      iTunesSubtitle: json['itunes_subtitle'],
      author: json['author'],
      episodeArt: json['episode_art'],
      explicit: json['explicit'],
      episodeType: json['episode_type'],
      episodeSeason: json['episode_season'],
      episodeNumber: json['episode_number'],
      donationLink: json['donation_link'],
      donationText: json['donation_text'],
      link: json['link'],
      iTunesBlock: json['itunes_block'],
    );
  }

  const Episode({
    this.showId,
    this.id,
    this.status,
    this.date,
    this.link,
    this.title,
    this.author,
    this.showNotes,
    this.summary,
    this.episodeArt,
    this.explicit,
    this.episodeType,
    this.episodeSeason,
    this.episodeNumber,
    this.mediaId,
    this.iTunesTitle,
    this.iTunesSubtitle,
    this.iTunesBlock,
    this.donationText,
    this.donationLink,
  });

  final String? showId;
  final String? id;

  final String? status;
  // Format: "YYYY-MM-DD HH:mm:ss"
  final String? date;
  final String? link;

  final String? title;
  final String? author;
  final String? showNotes;
  final String? summary;
  final String? episodeArt;
  final String? explicit;
  final String? episodeType;
  final String? episodeSeason;
  final String? episodeNumber;

  final String? mediaId;

  final String? iTunesTitle;
  final String? iTunesSubtitle;
  final String? iTunesBlock;

  final String? donationText;
  final String? donationLink;

  Map<String, String> toFormFields() {
    return {
      if (showId != null) //
        'shows_id': showId!,
      if (id != null) //
        'id': id!,
      if (title != null) //
        'title': title!,
      if (iTunesTitle != null) //
        'itunes_title': iTunesTitle!,
      if (mediaId != null) //
        'media_id': mediaId!,
      if (date != null) //
        'date': date!,
      if (status != null) //
        'status': status!,
      if (showNotes != null) //
        'shownotes': showNotes!,
      if (summary != null) //
        'summary': summary!,
      if (iTunesSubtitle != null) //
        'itunes_subtitle': iTunesSubtitle!,
      if (author != null) //
        'author': author!,
      if (episodeArt != null) //
        'episode_art': episodeArt!,
      if (explicit != null) //
        'explicit': explicit!,
      if (episodeType != null) //
        'episode_type': episodeType!,
      if (episodeSeason != null) //
        'episode_season': episodeSeason!,
      if (episodeNumber != null) //
        'episode_number': episodeNumber!,
      if (donationLink != null) //
        'donation_link': donationLink!,
      if (donationText != null) //
        'donation_text': donationText!,
      if (link != null) //
        'link': link!,
      if (iTunesBlock != null) //
        'itunes_block': iTunesBlock!,
    };
  }
}
