# # Ruleby tutoriel.
# 
# After some hesitation, I decided to write a complete tuto about using "Ruleby". I will try to be as short as possible, which mean you will
# need to read some official documentation at some moment. But the intended audience is people who may have heard about rule system but never 
# really seen it. Which also mean some information may be voluntary "inexact" in order to lower the learning curve. Of course there also may be 
# Totally wrong information just because of some error or even because of my english expression... If you do not figure why something is 
# "so inexact" please drop a message (or a pull request).
#
#
# # How to start
# First you need to know __WHAT__ is a "rule system". Please check this link where this job is already done : 
# https://github.com/Codalytics/ruleby/wiki/Introduction-to-Ruleby
# where you do not need to read the technical part (altough you will need it quite fast).
#
# So, great, now you know that rule system is. There is one thing you need to know before we dive in : 
# Understanding the interest of a rule system really __need__ you to use it and not only to read on example. 
# I show (TODO: conjugaison ?) this techno to few people during last ten years and the result was really interesting : everyone who just read
# about it did not see the interest of it. Everyone who tried - on one personnal exemple they had - alway have one available in their technological
# toolbox and use it as soon as they find it can help them. So if you want to really benefit from this tuto, first learn as usual, reading 
# it then, please, do not stop here. Try it on one of our problem. This is a matter of few hours. 
# 
# If you want to know on which problems a rule system will help you the more, read this : http://www.jessrules.com/jess/guidelines.shtml
# This is not about ruleby, but this apply to ruleby also.
# 
#
#
# # An alarm system.
#
# To fully use Ruleby, the main point is to know precisely :
#
# 1. how to write LHS, _Left Hand Side_, the conditionnal part of a rule.  
# 2. how to work with a facts databases. 
#
# The courrent DSL to write LHS should change in the future, but let's talk of how it works today.
# 
# Let's demonstrate this with rules for an alarm system for a fabric or computer room. First if someone push the alarm button, bell rings.
# 
# ## A simple (but wrong way) of ringing on button push.
# 
# Let say the button call method 'push' or 'release' when it changes state. The "name" is just here to show how to use binding feature :
# 

# Add to fact a Pushed button
def push
  assert( Button.new(:name => "alarm", :status=>:pushed) )
end

# Add to fact a Released button
def release
  assert( Button.new(:name => "alarm", :status=>:released) )
end

# The rule that process pushed buttons. No priority for this 1st exemple
rule :buttonPush, 
  # Here, you __need__ to understand that `method` is in fact the instance of Button that is currently matched against this pattern.
  # you can prononce it like :
  #
  # > _When I get Button event, I associate it with :button key of context, I call its method `name` and associate the result to
  #   :button\_name key of context, I check if its method `status` return `:pushed`. If yes, launch action._ 
  [Button,:button,{method.name=>:button_name}, method.status==:pushed] do |context|
    # Here we acces to value binded to the context hash
    button      = context[:button]
    button_name = context[:button_name]
    # Name can be used to log
    Logger.info("Button #{button_name} push handled at #{Time.now.to_s}")
    
    # Here we will need to define this "start_ringing" better... but one step at a time.
    start_ringing()
end

# Same kind of rule for button release. We do not use button_name here to show an other way of accessing object
rule :buttonRelease, 
  [Button,:button, method.status==:released] do |context|
    button      = context[:button]
    Logger.info("Button #{button.name} release handled at #{Time.now.to_s}")    
    # But... wait ! There is a start and a stop, maybe this mean there is a kind of "state", ie : is_ringing, for the ring ? .
    stop_ringing()
end

#
# ## Why is this wrong ?
# In this example facts are only added. After one push and one release you will find in the fact database two `Button` objects.
# One pushed, the other one released which is an inconsistent state. Furthermore the ring state is not handled but left to mystery 
# of `start_ringing` and `stop_ringing`. What if we want to write rules that use the ringing state ?
# 1st things, let's clean fact database. We have two possibilities.
# 
# ### retract facts in the rules.
# This is something we have to know, but maybe not the best thing to do here. Exemple with the buttonRelease rule
rule :buttonRelease, 
  [Button,:button, method.status==:released] do |context|
    button      = context[:button]
    Logger.info("Button #{button.name} release handled at #{Time.now.to_s}")    
    # But... wait ! There is a start and a stop, maybe this mean there is a kind of "state", ie : is_ringing, for the ring ? .
    stop_ringing()
    # Here we do :
    retract button
end

#
# ### Maintain a external state.
# You may think "The button is an external device and thus should be handled by an external object". Well, I would say "handle this technique with care" ! 
# Sharing state between rule engine and the external word is really something risky if done improperly. The way of doing it is to keep a ref 
# to the state objet, let's use a wrapping object to do it well, then tell the rule engine after each modification. 
# In this exemple the name `Button` is kept for the class, even if `ButtonState` would be more appropriate.
# I am just using a feature of common developpers called _Laziness_ which lead them to deploy incredible way of working with code they had 
# made unclear this way. In this case this avoid me changin slighlty the above rules's LHS. This is the typical kind of case where you really
# should avoid handling external states... But this technique is sometime the most adapted to a situation (Please send me correction proposal if you disagree with this). 
#
class ButtonInterface
  def initialize(button_name, rule_engine)
    @button = Button.new(:name => button_name, :status=>:released)
    @engine = rule_engine
    @engine.assert @button
  end
  
  def push
    @button.status = :pushed
    @engine.modify @button
  end
  
  def release
    @button.status = :released
    @engine.modify @button
  end
end

# ### Maintain an internal state in facts database
# Ok, here we are ! What is behind this idea ? Guess ?
# If you hold a state in facts database, why would you send to the rule engine an other state ? Why not just handle "Events" and let the rule engine manage states consistently inside itself ? 
# Let see next chapter.

# # Splitting states and events.
#
# In this exemple Button convey a state and is used when something change... It is used as an event ! 
# What we could do is :
# * Change states (and send engine.modify) inside rules. 
# * Use simple rules which can handle events and change states if needed. 



