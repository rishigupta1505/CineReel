import 'dart:async';
import 'dart:io';

import 'package:cine_reel/bloc/movie_bloc.dart';
import 'package:cine_reel/models/tmdb_genres.dart';
import 'package:cine_reel/models/tmdb_movie_basic.dart';
import 'package:cine_reel/ui/list_screen/movie_row/poster_row.dart';
import 'package:cine_reel/ui/list_screen/movies_list_widget.dart';
import 'package:cine_reel/ui/scroll_controller/list_controller.dart';
import 'package:cine_reel/utils/tab_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../fixtures/genres_fixtures.dart';
import '../../fixtures/movie_fixtures.dart';
import 'image_mock_http_client.dart';

class MockMovieBloc extends Mock implements MovieBloc {}

void main() {
  MockMovieBloc mockMovieBloc;
  List<TMDBMovieBasic> movieList = [mockMovieOne, mockMovieTwo, mockMovieThree];
  ListController listController;
  ListView listview;
  var listviewFinder = find.byType(ListView);

  setUp(() {
    HttpOverrides.global = MyHttpOverrides();

    mockMovieBloc = MockMovieBloc();
    when(mockMovieBloc.nextPage).thenAnswer((_) => StreamController().sink);
  });

  Future pumpMainWidget(WidgetTester tester, MovieBloc movieBloc, List<TMDBMovieBasic> movies,
      [TMDBGenre genre = null]) async {
    await tester.pumpWidget(MaterialApp(
        home: MovieListWidget(
      movies: movies,
      movieBloc: movieBloc,
      tabKey: TabKey.kNowPlaying,
      genre: genre,
    )));

    listview = getListView(tester, listviewFinder);
    listController = listview.controller;
  }

//	testWidgets('should go to movie details when tapped', (WidgetTester tester) async {
//		await pumpMainWidget(tester, mockMovieBloc, movieList);
//
//		expect(find.text(movieList[0].title), findsOneWidget);
////		await tester.tap(find.text(movieList[0].title));
//		await tester.tap(find.byKey(Key(movieList[0].title)));
//		await tester.pumpAndSettle();
//
//		expect(find.byType(MovieDetailsWidget), findsOneWidget);
//	});

  testWidgets('should have a Listview', (WidgetTester tester) async {
    await pumpMainWidget(tester, mockMovieBloc, movieList);
    expect(listviewFinder, findsOneWidget);
  });

  testWidgets('listView should have poster rows', (WidgetTester tester) async {
    await pumpMainWidget(tester, mockMovieBloc, movieList);
    expect(find.byType(PosterRow), findsNWidgets(movieList.length));
  });

  testWidgets('listView should have a list controller', (WidgetTester tester) async {
    await pumpMainWidget(tester, mockMovieBloc, movieList);
    expect(listview.controller, isNotNull);
  });

  testWidgets('list controller should have a listener', (WidgetTester tester) async {
    await pumpMainWidget(tester, mockMovieBloc, movieList);
    expect(listController.hasListeners, isTrue);
  });

  testWidgets('should request next page when close to the end of the listview',
      (WidgetTester tester) async {
    await pumpMainWidget(tester, mockMovieBloc, movieList);
    listController.position.jumpTo(10.0);
    verify(mockMovieBloc.nextPage);
  });

  testWidgets('should not request next page when list controller is paused',
      (WidgetTester tester) async {
    await pumpMainWidget(tester, mockMovieBloc, movieList);
    listController.pause();

    listController.position.jumpTo(10.0);

    verifyNever(mockMovieBloc.nextPage);
  });

  testWidgets('should pause list controller after requesting next page',
      (WidgetTester tester) async {
    await pumpMainWidget(tester, mockMovieBloc, movieList);
    expect(listController.isPaused, isFalse);

    listController.position.jumpTo(10.0);

    verify(mockMovieBloc.nextPage);
    expect(listController.isPaused, isTrue);
  });

  testWidgets('should show listview when movies present', (WidgetTester tester) async {
    await pumpMainWidget(tester, mockMovieBloc, movieList);
    AnimatedOpacity animatedOpacity = tester.widget(find.byType(AnimatedOpacity));
    expect(animatedOpacity.opacity, 1.0);
  });

  testWidgets('should hide listview when movies not present', (WidgetTester tester) async {
    await pumpMainWidget(tester, mockMovieBloc, []);
    AnimatedOpacity animatedOpacity = tester.widget(find.byType(AnimatedOpacity));
    expect(animatedOpacity.opacity, 0.0);
  });

  testWidgets('should have Scaffold, AppBar and correct genre title if genres available',
					(WidgetTester tester) async {
    await pumpMainWidget(tester, mockMovieBloc, movieList, genreOne);
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
    AppBar appBar = tester.widget(find.byType(AppBar));
    expect((appBar.title as Text).data, genreOne.name);
  });
}

ListView getListView(WidgetTester tester, Finder listviewFinder) {
  ListView listView = tester.widget(listviewFinder);
  return listView;
}
