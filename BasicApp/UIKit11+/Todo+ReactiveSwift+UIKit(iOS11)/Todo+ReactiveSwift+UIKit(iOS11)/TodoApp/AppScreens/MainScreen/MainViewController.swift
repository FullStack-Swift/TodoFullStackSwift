import ComposableArchitecture
import SwiftUI
import UIKit
import ConvertSwift
import ReactiveCocoa

final class MainViewController: BaseViewController {
  
  private let store: Store<MainState, MainAction>
  
  private let viewStore: ViewStore<MainState, MainAction>
  
  private let tableView: UITableView = UITableView()
  
  init(store: Store<MainState, MainAction>? = nil) {
    let unwrapStore = store ?? Store(initialState: MainState(), reducer: MainReducer, environment: MainEnvironment())
    self.store = unwrapStore
    self.viewStore = ViewStore(unwrapStore)
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    viewStore.send(.viewDidLoad)
    // navigationView
    let buttonLogout = UIButton(type: .system)
    buttonLogout.setTitle("Logout", for: .normal)
    buttonLogout.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
    buttonLogout.setTitleColor(UIColor.blue, for: .normal)
    let rightBarButtonItem = UIBarButtonItem(customView: buttonLogout)
    navigationController?.navigationBar.prefersLargeTitles = true
    navigationItem.largeTitleDisplayMode = .always
    navigationItem.rightBarButtonItem = rightBarButtonItem
    // tableView
    view.addSubview(tableView)
    tableView.register(MainTableViewCell.self)
    tableView.register(ButtonReloadMainTableViewCell.self)
    tableView.register(CreateTitleMainTableViewCell.self)
    tableView.showsVerticalScrollIndicator = false
    tableView.showsHorizontalScrollIndicator = false
    tableView.delegate = self
    tableView.dataSource = self
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.isUserInteractionEnabled = true
      // contraint
      NSLayoutConstraint.activate([
        tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
        tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
        tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
        tableView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -10)
      ])

    //bind view to viewstore
    disposables += viewStore.action <~ buttonLogout.reactive.controlEvents(.touchUpInside).map {_ in MainAction.logout}
    
    //bind viewstore to view
    disposables += viewStore.publisher.todos.producer
      .startWithValues({ [weak self] _ in
        guard let self = self else {return}
        self.tableView.reloadData()
      })
    disposables += reactive.title <~ viewStore.publisher.todos.count.producer.map {$0.toString() + " Todos"}
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    viewStore.send(.viewWillAppear)
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    viewStore.send(.viewWillDisappear)
  }
  
  deinit {
    viewStore.send(.viewDeinit)
  }
}

extension MainViewController: UITableViewDataSource {
  func numberOfSections(in tableView: UITableView) -> Int {
    return 3
  }
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    switch section {
    case 0:
      return 1
    case 1:
      return 1
    case 2:
      return viewStore.todos.count
    default:
      return 0
    }
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    switch indexPath.section {
    case 0:
      let cell = tableView.dequeueReusableCell(ButtonReloadMainTableViewCell.self, for: indexPath)
      cell.selectionStyle = .none
      cell.disposables += viewStore.publisher.isLoading.producer.startWithValues({ value in
        cell.buttonReload.isHidden = value
        if value {
          cell.activityIndicator.startAnimating()
        } else {
          cell.activityIndicator.stopAnimating()
        }
      })
      cell.disposables += viewStore.action <~ cell.buttonReload.reactive.controlEvents(.touchUpInside).map {_ in MainAction.viewReloadTodo}
      return cell
    case 1:
      let cell = tableView.dequeueReusableCell(CreateTitleMainTableViewCell.self, for: indexPath)
      cell.disposables += cell.titleTextField.reactive.text <~ viewStore.publisher.title.producer
      cell.disposables += viewStore.publisher.title.isEmpty.producer.startWithValues { value in
        cell.createButton.setTitleColor(value ? UIColor.gray : UIColor.green, for: .normal)
      }
      cell.disposables += viewStore.action <~ cell.createButton.reactive.controlEvents(.touchUpInside).map {_ in MainAction.viewCreateTodo}
      cell.disposables += viewStore.action <~ cell.titleTextField.reactive.continuousTextValues.map {MainAction.changeText($0)}
      return cell
    case 2:
      let cell = tableView.dequeueReusableCell(MainTableViewCell.self, for: indexPath)
      let todo = viewStore.todos[indexPath.row]
      cell.bind(todo)
      cell.disposables += viewStore.action <~ cell.deleteButton.reactive.controlEvents(.touchUpInside).map { _ in MainAction.viewDeleteTodo(todo)}
      cell.disposables += viewStore.action <~ cell.tapGesture.reactive.stateChanged.map { _ in MainAction.viewToggleTodo(todo)}
      return cell
    default:
      let cell = tableView.dequeueReusableCell(MainTableViewCell.self, for: indexPath)
      return cell
    }
  }
}

extension MainViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 60
  }
}
