### Prototype for a modular contract design

#### Summary 

Create structure , attach modules that has different actions , add rules to mod the action's behaviour

#### Design Pattern 
1. For every game action there is a request. 
2. The request may have rules to be satisfied to suceed 
3. The rules are defined as requirements 

**Technical :**

- Request is a true hot-potato that makes sure any action/interaction/state change satisfies a bunch of rules
- A rule is a policy ("structure must be online"). 
- A requirement is the instance of that rule attached to a specific action — a checkbox to tick.
