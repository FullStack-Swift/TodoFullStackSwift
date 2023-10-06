import ComposableArchitecture
import SwiftUI
import UIKit
import Combine
import RxCocoa

final class AuthViewController: UIViewController {
  
  private let store: Store<AuthState, AuthAction>
  
  private let viewStore: ViewStore<ViewState, ViewAction>
  
  private let disposeBag = DisposeBag()
  
  init(store: Store<AuthState, AuthAction>? = nil) {
    let unwrapStore = store ?? Store(initialState: AuthState(), reducer: AuthReducer, environment: AuthEnvironment())
    self.store = unwrapStore
    self.viewStore = ViewStore(unwrapStore.scope(state: ViewState.init, action: AuthAction.init))
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .white
      /// buttonLogin
    let buttonLogin = UIButton(type: .system)
    buttonLogin.setTitle("Login", for: .normal)
    buttonLogin.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
    buttonLogin.setTitleColor(UIColor(Color.blue), for: .normal)
    buttonLogin.translatesAutoresizingMaskIntoConstraints = false
    buttonLogin.backgroundColor = UIColor(Color.gray.opacity(0.2))
    buttonLogin.setTitleColor(UIColor(Color.black), for: .normal)
    NSLayoutConstraint.activate([
      buttonLogin.heightAnchor.constraint(equalToConstant: 52)
    ])
      /// buttonRegister
    let buttonRegister = UIButton(type: .system)
    buttonRegister.setTitle("Register", for: .normal)
    buttonRegister.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
    buttonRegister.setTitleColor(UIColor(Color.blue), for: .normal)
    buttonRegister.translatesAutoresizingMaskIntoConstraints = false
    buttonRegister.backgroundColor = UIColor(Color.black)
    buttonRegister.setTitleColor(UIColor(Color.white), for: .normal)
    NSLayoutConstraint.activate([
      buttonRegister.heightAnchor.constraint(equalToConstant: 52)
    ])
    
      /// containerView
    let rootStackView = UIStackView(arrangedSubviews: [
      buttonLogin,
      buttonRegister
    ])
    rootStackView.translatesAutoresizingMaskIntoConstraints = false
    rootStackView.alignment = .center
    rootStackView.spacing = 10
    rootStackView.distribution = .fillEqually
    view.addSubview(rootStackView)
    NSLayoutConstraint.activate([
      rootStackView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 20),
      rootStackView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -20),
      rootStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
      rootStackView.heightAnchor.constraint(equalToConstant: 82)
    ])
    
    // title
    let titleLabel = UILabel()
    titleLabel.text = "TodoList"
    titleLabel.font = UIFont.boldSystemFont(ofSize: 30)
    titleLabel.textAlignment = .center
    titleLabel.textColor = .white
    titleLabel.backgroundColor = UIColor(Color.green)
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(titleLabel)
    NSLayoutConstraint.activate([
      titleLabel.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 0),
      titleLabel.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: 0),
      titleLabel.bottomAnchor.constraint(equalTo: rootStackView.topAnchor, constant: 0),
      titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0),
    ])
    
      //bind view to viewstore
    buttonLogin.rx.tap
      .map{ViewAction.setNavigation(isActive: true, screen: .login)}
      .subscribe(viewStore.action)
      .disposed(by: disposeBag)
    
    buttonRegister.rx.tap
      .map{ViewAction.setNavigation(isActive: true, screen: .register)}
      .subscribe(viewStore.action)
      .disposed(by: disposeBag)
    
    store
      .scope(state: \.loginState, action: AuthAction.loginAction)
      .ifLet(
        then: { [weak self] store in
          self?.navigationController?.pushViewController(
            LoginViewController(store: store), animated: true)
        },
        else: { [weak self] in
          guard let self = self else { return }
          self.navigationController?.popToViewController(self, animated: true)
        }
      )
      .disposed(by: disposeBag)
    
    store
      .scope(state: \.registerState, action: AuthAction.registerAction)
      .ifLet(
        then: { [weak self] store in
          guard let self = self else { return }
          self.navigationController?.pushViewController(
            RegisterViewController(store: store), animated: true)
        },
        else: { [weak self] in
          guard let self = self else { return }
          self.navigationController?.popToViewController(self, animated: true)
        }
      )
      .disposed(by: disposeBag)
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    if !isMovingToParent {
      viewStore.send(.setNavigation(isActive: false, screen: .root))
    }
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    navigationController?.setNavigationBarHidden(true, animated: animated)
    viewStore.send(.viewWillAppear)
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    viewStore.send(.viewWillDisappear)
    navigationController?.setNavigationBarHidden(false, animated: animated)
  }
}

struct AuthViewController_Previews: PreviewProvider {
  static var previews: some View {
    let vc = AuthViewController()
    vc.toSwifUIView()
  }
}

fileprivate struct ViewState: Equatable {
  init(state: AuthState) {
    
  }
}

fileprivate enum ViewAction: Equatable {
  case viewDidLoad
  case viewWillAppear
  case viewWillDisappear
  case none
  case setNavigation(isActive: Bool, screen: AuthScreen)
  
  init(action: AuthAction) {
    switch action {
    case .viewDidLoad:
      self = .viewDidLoad
    case .viewWillAppear:
      self = .viewWillAppear
    case .viewWillDisappear:
      self = .viewWillDisappear
    default:
      self = .none
    }
  }
}

fileprivate extension AuthAction {
  init(action: ViewAction) {
    switch action {
    case .viewDidLoad:
      self = .viewDidLoad
    case .viewWillAppear:
      self = .viewWillAppear
    case .viewWillDisappear:
      self = .viewWillDisappear
    case .setNavigation(isActive: let isActive, screen: let screen):
      self = .setNavigation(isActive: isActive, screen: screen)
    default:
      self = .none
    }
  }
}
