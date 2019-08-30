//
//  RxDataSource.swift
//  NetflixPOC
//
//  Created by Mark Randall on 8/30/19.
//

import Foundation
import DataSources
import RxSwift

///
/// Having some fun with DataSources
/// Goal is to make configuring a UITableView or UICollectionView datasource as readable as possible at the call site
/// One line feeds pretty good :)
///

protocol RxDataSourceCell {
    
    associatedtype ViewModel
    
    // If using a nib assumes nib has same name as reuseIdentifier
    // If using a class assumes class name is same as reuseIdentifier
    static var reuseIdentifier: String { get }
        
    func bind(viewModel: ViewModel)
}

final class RxDataSource<T, U>: ArrayDataSource<T, U> {
    
    private let dataUpdated: () -> Void
    private let disposeBag = DisposeBag()
    
    fileprivate init(observable: Observable<[T]>, cellReuseIdentifier: String, dataUpdated: @escaping () -> Void, cellConfiguration: CellConfiguration?) {
        self.dataUpdated = dataUpdated
        super.init(data: [], cellReuseIdentifier: cellReuseIdentifier, cellConfiguration: cellConfiguration)
        
        observable.subscribe(onNext: { [weak self] in
            self?.data = $0
            self?.dataUpdated()
        }).disposed(by: disposeBag)
    }
}

///
/// TODO: Hide Dwifft or Swift 5.1 diffing behind the scenes. Should be possible without touching datasource creation.
///

extension UITableView {
    
    func create<T, U: RxDataSourceCell>(
        usingNib: Bool = true,
        observable: Observable<[T]>
    ) -> RxDataSource<T, U> where U.ViewModel == T {
        
        if usingNib {
            self.register(UINib(nibName: U.reuseIdentifier, bundle: nil), forCellReuseIdentifier: U.reuseIdentifier)
        } else {
            preconditionFailure("TODO")
        }
        
        let dataSource = RxDataSource(
            observable: observable,
            cellReuseIdentifier: U.reuseIdentifier,
            dataUpdated: ({ self.reloadData() })
        ) { (cell: U, _, data: T) in
            cell.bind(viewModel: data)
        }
        self.dataSource = dataSource
        
        return dataSource
    }
}

extension UICollectionView {
    
    func create<T, U: RxDataSourceCell>(
        usingNib: Bool = true,
        observable: Observable<[T]>
    ) -> RxDataSource<T, U> where U.ViewModel == T {
        
        if usingNib {
            self.register(UINib(nibName: U.reuseIdentifier, bundle: nil), forCellWithReuseIdentifier: U.reuseIdentifier)
        } else {
            preconditionFailure("TODO")
        }
        
        let dataSource = RxDataSource(
            observable: observable,
            cellReuseIdentifier: U.reuseIdentifier,
            dataUpdated: ({ self.reloadData() })
        ) { (cell: U, _, data: T) in
            cell.bind(viewModel: data)
        }
        self.dataSource = dataSource
        
        return dataSource
    }
}
