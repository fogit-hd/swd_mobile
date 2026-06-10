import '../models/review_session.dart';

bool publishedReviewOnly(ReviewSession session) => session.isPublished;

bool submittedReviewOnly(ReviewSession session) => session.canViewResults;
