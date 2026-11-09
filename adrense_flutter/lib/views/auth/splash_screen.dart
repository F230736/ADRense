part of '../../main.dart';

extension _SplashViews on _ADRenseAppState {
  Widget splash()=>CinematicSplash(
    onGetStarted:()=>setState(() {register=true;screen='login';}),
    onSignIn:()=>setState(() {register=false;screen='login';}),
  );

}
