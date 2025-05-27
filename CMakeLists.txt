cmake_minimum_required(VERSION 3.21)

project(gymWeights VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick)

qt_standard_project_setup(REQUIRES 6.5)

qt_add_executable(appgymWeights
    main.cpp
)

if(ANDROID)
    # Usar tu manifiesto directamente
    configure_file(
        ${CMAKE_SOURCE_DIR}/android/src/main/AndroidManifest.xml
        ${CMAKE_BINARY_DIR}/android-build/AndroidManifest.xml
        COPYONLY
    )

    set(ANDROID_PACKAGE_NAME "com.dreSoft.weightAndSee")
    set(ANDROID_APP_NAME "Weight&See")

    set_property(TARGET appgymWeights PROPERTY QT_ANDROID_APPLICATION_CLASS "org.qtproject.qt.android.bindings.QtApplication")
    set_property(TARGET appgymWeights PROPERTY QT_ANDROID_PACKAGE_SOURCE_DIR "${CMAKE_SOURCE_DIR}/android/src/main")
endif()

set_source_files_properties(qml/Style.qml
    PROPERTIES QT_QML_SINGLETON_TYPE TRUE
)

qt_add_qml_module(appgymWeights
    URI gymWeights
    VERSION 1.0
    QML_FILES
        Main.qml
        qml/MenuPage.qml
        qml/ExerciseDelegate.qml
        qml/SearchBox.qml
        qml/MuscleGroupFilter.qml
        qml/NewExerciseDialog.qml
        qml/EditExerciseDialog.qml
        qml/ConfirmDeleteDialog.qml
        qml/HistoryDialog.qml
        qml/GraphPage.qml
        qml/Tooltip.qml
        qml/HistoryDelegate.qml
        qml/SummaryItem.qml
        qml/SummaryGrid.qml
        qml/NumericTextField.qml
        qml/SettingsPage.qml
        qml/MessagePopup.qml
        qml/FloatButton.qml
        qml/Style.qml
        qml/Splash.qml
        qml/NumberSpinner.qml
    SOURCES
        datacenter.h datacenter.cpp
        exercisemodel.h exercisemodel.cpp
        exerciseprovider.h exerciseprovider.cpp
)

qt_add_resources(appgymWeights "icons"
    FILES
        icons/core.png
        icons/trash.png
        icons/arms.svg
        icons/back.svg
        icons/chest.svg
        icons/core.svg
        icons/shoulders.svg
        icons/legs.svg
        icons/settings.png
        icons/uk.png
        icons/spain.png
        icons/appSplash.png
)

qt_add_resources(appgymWeights "fonts"
    FILES
        fonts/Inter-Medium.ttf
)

qt_add_resources(appgymWeights "data"
    FILES
        data/exerciseList.txt
)

set_target_properties(appgymWeights PROPERTIES
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(appgymWeights
    PRIVATE Qt6::Quick
)

include(GNUInstallDirs)
install(TARGETS appgymWeights
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

set(CMAKE_SKIP_BUILD_RPATH TRUE)
