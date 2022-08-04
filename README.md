# Spanish Word Game

## Project Details
SpanishGame implemented as a single screen application. MVVM pattern is used for the architecture.
Model construcs:
* WordPairStorage: Loads and caches word list.
* TransactionsInteractor: Fetches word pairs from the storage and also responsible from creating tranlations.
* RoundTimer: Utility for tracking round durations.

## Q&A
* How much time was invested:
Approximately 6 hours.

* How was the time distributed (concept, model layer, view(s), game mechanics):
Most of the time spent on designing the consept, game mechanics and the architecture. Other aspects implemented by the architecture. View & ViewModel took the secondmost time. Model layer is very straightforward and implemented as simple constructs that follow the common design patterns.

* Decisions made to solve certain aspects of the game:
Because this is a simple project it's designed as single screen. View layer is created with UIKit based views & designed with storyboards. MVVM patten is choosen for the seperation of ui and business logic. Game data is stored in memory because it is relatively small and stored in local storage. A simple storage object manages loading and accessing the data. A single interactor handles the conversion of the data.

* Decisions made because of restricted time:
It would be better if the initial loading & game over parts implemented as a seperate module idealy with their own view models and more animations. 

* What would be the first thing to improve or add if there had been more time:
Communication between the view and view model is done manualy and it would better if an rx framework like Combine is used. 
