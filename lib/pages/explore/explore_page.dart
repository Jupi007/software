import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snapd/snapd.dart';
import 'package:software/l10n/l10n.dart';
import 'package:software/pages/explore/app_banner.dart';
import 'package:software/pages/explore/app_dialog.dart';
import 'package:software/pages/explore/app_grid.dart';
import 'package:software/pages/explore/explore_model.dart';
import 'package:software/pages/common/snap_section.dart';
import 'package:yaru_icons/yaru_icons.dart';
import 'package:yaru_widgets/yaru_widgets.dart';

class ExplorePage extends StatelessWidget {
  const ExplorePage({Key? key}) : super(key: key);

  static Widget create(BuildContext context) {
    final client = context.read<SnapdClient>();
    return ChangeNotifierProvider(
      create: (_) => ExploreModel(client),
      child: const ExplorePage(),
    );
  }

  static Widget createTitle(BuildContext context) =>
      Text(context.l10n.explorePageTitle);

  @override
  Widget build(BuildContext context) {
    final model = context.watch<ExploreModel>();
    final width = MediaQuery.of(context).size.width;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SizedBox(
            height: 60,
            child: Row(
              children: [
                _FilterPill(
                  onPressed: () => model.searchActive = !model.searchActive,
                  selected: model.searchActive,
                  iconData: YaruIcons.search,
                ),
                if (!model.searchActive)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: _FilterPill(
                      onPressed: () => model.exploreMode = !model.exploreMode,
                      selected: model.exploreMode,
                      iconData: YaruIcons.image,
                    ),
                  ),
                if (!model.searchActive)
                  _FilterPill(
                    onPressed: () => model.exploreMode = !model.exploreMode,
                    selected: !model.exploreMode,
                    iconData: YaruIcons.format_unordered_list,
                  ),
                if (!model.exploreMode || model.searchActive)
                  Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: IntrinsicHeight(
                      child: SizedBox(
                        height: 40,
                        child: VerticalDivider(
                          width: 20,
                          thickness: 0.5,
                        ),
                      ),
                    ),
                  ),
                model.searchActive
                    ? Expanded(child: _SearchField())
                    : ChangeNotifierProvider.value(
                        value: model,
                        child: Expanded(
                            child: !model.exploreMode
                                ? _FilterBar()
                                : SizedBox())),
              ],
            ),
          ),
        ),
        Expanded(
          child: YaruPage(
            padding: EdgeInsets.only(left: 20, right: 20, bottom: 20),
            children: [
              if (width < 1000 && !model.searchActive && model.exploreMode)
                _AppBannerCarousel(),
              if (model.searchActive)
                AppGrid(
                  topPadding: 20,
                  name: model.searchQuery,
                  findByName: true,
                ),
              if (!model.searchActive && !model.exploreMode)
                for (int i = 0; i < model.filters.entries.length; i++)
                  if (model.filters.entries.elementAt(i).value == true)
                    AppGrid(
                      topPadding: i == 0 ? 20 : 40,
                      name: model.filters.entries.elementAt(i).key.title(),
                      headline: model.filters.entries.elementAt(i).key.title(),
                      findByName: false,
                    ),
              if (!model.searchActive && model.exploreMode)
                ChangeNotifierProvider.value(
                  value: model,
                  child: ExploreGrid(snapSection: SnapSection.featured),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SearchField extends StatefulWidget {
  const _SearchField({Key? key}) : super(key: key);

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  TextEditingController _controller = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final model = context.watch<ExploreModel>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: TextField(
        controller: _controller,
        onChanged: (value) => model.searchQuery = value,
        autofocus: true,
        decoration: InputDecoration(
          prefixIcon: model.searchQuery == ''
              ? null
              : IconButton(
                  splashRadius: 20,
                  onPressed: () {
                    model.searchQuery = '';
                    _controller.text = '';
                  },
                  icon: Icon(YaruIcons.edit_clear)),
          isDense: false,
          border: UnderlineInputBorder(),
        ),
      ),
    );
  }
}

class _FilterBar extends StatefulWidget {
  const _FilterBar({Key? key}) : super(key: key);

  @override
  State<_FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends State<_FilterBar> {
  final ScrollController _controller = ScrollController();

  @override
  Widget build(BuildContext context) {
    final model = context.watch<ExploreModel>();
    return SizedBox(
      width: 1000,
      child: ScrollbarTheme(
        data: ScrollbarThemeData(
            thumbVisibility: MaterialStateProperty.resolveWith((states) =>
                states.contains(MaterialState.hovered) ? true : false)),
        child: Scrollbar(
          controller: _controller,
          child: ListView(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            shrinkWrap: true,
            children: [
              for (final section in model.selectedFilters)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: _FilterPill(
                      tooltip: section.title(),
                      onPressed: () => model.setFilter(snapSections: [section]),
                      selected: model.filters[section]!,
                      iconData: snapSectionToIcon[section]!),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String getSectionTranslation(BuildContext context) {
    return '';
  }
}

class _AppBannerCarousel extends StatelessWidget {
  const _AppBannerCarousel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final model = context.read<ExploreModel>();
    final size = MediaQuery.of(context).size;
    return FutureBuilder<List<Snap>>(
      future: model.findSnapsBySection(section: 'featured'),
      builder: (context, snapshot) => snapshot.hasData
          ? Padding(
              padding: const EdgeInsets.only(
                bottom: 20,
              ),
              child: YaruCarousel(
                margin: EdgeInsets.zero,
                viewportFraction: 1,
                placeIndicator: false,
                autoScrollDuration: Duration(seconds: 3),
                width: size.width,
                height: 178,
                autoScroll: true,
                children: snapshot.data!
                    .take(10)
                    .map(
                      (snap) => AppBanner(
                        snap: snap,
                        onTap: () => showDialog(
                          barrierColor: Colors.black.withOpacity(0.9),
                          context: context,
                          builder: (context) => ChangeNotifierProvider.value(
                            value: model,
                            child: AppDialog(snap: snap),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            )
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: YaruCircularProgressIndicator(),
              ),
            ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final IconData iconData;
  final bool selected;
  final Function()? onPressed;
  final String? tooltip;

  _FilterPill({
    Key? key,
    required this.selected,
    required this.iconData,
    this.onPressed,
    this.tooltip,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundColor: selected
          ? Theme.of(context).colorScheme.onSurface.withOpacity(0.05)
          : Colors.transparent,
      child: IconButton(
        tooltip: tooltip,
        color: selected ? Colors.grey : null,
        splashRadius: 20,
        onPressed: onPressed,
        icon: Icon(
          iconData,
          color: selected
              ? Theme.of(context).primaryColor
              : Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
        ),
      ),
    );
  }
}

class ExploreGrid extends StatelessWidget {
  const ExploreGrid({Key? key, required this.snapSection}) : super(key: key);

  final SnapSection snapSection;

  @override
  Widget build(BuildContext context) {
    final model = context.watch<ExploreModel>();
    return FutureBuilder<List<Snap>>(
      future: model.findSnapsBySection(section: snapSection.title()),
      builder: (context, snapshot) => snapshot.hasData
          ? GridView(
              shrinkWrap: true,
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                mainAxisExtent: 150,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                maxCrossAxisExtent: 500,
              ),
              children: snapshot.data!
                  .map((snap) => AppBanner(
                        surfaceTint: false,
                        snap: snap,
                        onTap: () => showDialog(
                          barrierColor: Colors.black.withOpacity(0.9),
                          context: context,
                          builder: (context) => ChangeNotifierProvider.value(
                            value: model,
                            child: AppDialog(snap: snap),
                          ),
                        ),
                      ))
                  .toList(),
            )
          : YaruCircularProgressIndicator(),
    );
  }
}
