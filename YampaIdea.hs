{-# LANGUAGE GADTs #-}
--Informal idea: Have Yampa with data sources & sinks and explicit timing mechanisms/sampling strategies/"clocks", called animators. (I don't like the word "clock" since an animator doesn't actually show the time.
--After a discussion with Henrik Nilsson 2014.12.04 (?)


--Different animator types correspond to different sampling strategies, say 44100 Hz sound, 25 fps video, "as fast as the processor can do" video games, Arduino or your favourite hardware, event based (discrete, push), every hour, etc.
--This should 
class Animator a where
	animate	:: a -> IO ()
	sync	:: a -> a -> a -- Not sure whether this makes sense still... the idea is to have a trivial combinator whenever we combine two of the *same* animators, say if we read from the same hardware in one IO cycle. Maybe 'control' is the more appropriate choice.
	control	:: Animator b => a -> b -> a -- Returns an animator that drives the animator in the second argument, e.g., by downsampling. I really want a parametrised type here: animator *types* should form a (partial) order specifying the priority or urgency of that type of animator. The type system should then forbid controlling an urgent (e.g. realtime) animator with a less urgent one. Say, the video production cannot drive the sound system, but the other way around. A workaround is maybe having animators being an instance of Ord, and throwing an error whenever someone tries to control an urgent animator with a less urgent one.

--Here is a type-safe, crude alternative to the last problem:

class UsualAnimator a where
	animateU	:: a -> IO ()

class UsualAnimator a => UrgentAnimator a where
	controlU	:: UsualAnimator b => a -> b -> a

--I don't have a semantics if someone runs the same animator twice in different threads. It should probably raise an exception or block in some way. I don't know of a way how to fix that.

--Actually implement Animator a => SFA a b c instead of the following incomplete placeholder

data SFA a b c where
	arr :: Animator a => b -> c -> SFA a b c -- this doesn't compile... not sure what I'm doing wrong
	>>> :: Animator a => SFA a b c -> SFA a c d -> SFA a b d -- Can only trivially combine SFs with the same animator!


--Given an explicit way of combining animators, we can plug SFs with different animators together:
plug :: (Animator a, Animator b, Animator c) => (a -> b -> c) -> SFA a d e -> SFA b e f -> SFA c d f

--Data sources should just be signal functions that produce "stuff out of nothing". The information on how to do the IO should be in the animator
type Animator a => DataSource a b = SFA a () b

reactimate :: Animator a => SFA a () () -> IO ()
