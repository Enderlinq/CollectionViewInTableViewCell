
# Demo of UICollectionView within UITableViewCells
POC of what was once part of the iOS Netflix app UI. - CollectionView (or at least horizontally scrolling items) with TableView Cells (vertically scrolling).

# Worth noting
## TableView and CollectionView Datasource abstraction using RxSwift

```swift
/// Configuring a datasource with a single line of code. 
dataSource = tableView.createDataSource(bindTo: viewModel.viewState)
```

## Custom expand transition 
UIViewControllerAnimatedTransitioning + UIPresentationController + Bill Murry's face
