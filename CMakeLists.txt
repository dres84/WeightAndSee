cmake_minimum_required(VERSION 3.16)

project(gymWeights VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick)

qt_standard_project_setup(REQUIRES 6.5)

qt_add_executable(appgymWeights
    main.cpp
)

set_source_files_properties(qml/Style.qml
    PROPERTIES QT_QML_SINGLETON_TYPE TRUE
)

qt_add_qml_module(appgymWeights
    URI gymWeights
    VERSION 1.0
    QML_FILES
        Main.qml
        qml/MenuPage.qml
        qml/NavigationHeader.qml
        qml/ExerciseDelegate.qml
        qml/SearchBox.qml
        qml/MuscleGroupFilter.qml
        qml/NewExerciseDialog.qml
        qml/EditExerciseDialog.qml
        qml/ExerciseGraph.qml
        qml/Tooltip.qml
        qml/HistoryDelegate.qml
        qml/SummaryItem.qml
        qml/SummaryGrid.qml
        qml/NumericTextField.qml
        qml/FloatButton.qml
        qml/Style.qml
    RESOURCES
        android/AndroidManifest.xml
        android/build.gradle
        qml.qrc
    SOURCES
        datacenter.h datacenter.cpp
        exercisemodel.h exercisemodel.cpp
        exerciseprovider.h exerciseprovider.cpp

#    RESOURCES icons/core.png icons/tren_inferior.png icons/tren_superior.png
)

qt_add_resources(appgymWeights "icons"
#    PREFIX "/icons"
    FILES
        icons/core.png
        icons/tren_inferior.png
        icons/tren_superior.png
        icons/trash.png
        icons/search.png
        icons/arms.svg
        icons/back.svg
        icons/chest.svg
        icons/core.svg
        icons/shoulders.svg
        icons/legs.svg
        icons/settings.png
)

qt_add_resources(appgymWeights "fonts"
#    PREFIX "/fonts"
    FILES
        fonts/Inter-Medium.ttf
)

qt_add_resources(appgymWeights "data"
#    PREFIX "/data"
    FILES
        data/exerciseList.txt
)

# Qt for iOS sets MACOSX_BUNDLE_GUI_IDENTIFIER automatically since Qt 6.1.
# If you are developing for iOS or macOS you should consider setting an
# explicit, fixed bundle identifier manually though.
set_target_properties(appgymWeights PROPERTIES
#    MACOSX_BUNDLE_GUI_IDENTIFIER com.example.appgymWeights
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

# Limita la búsqueda de QtCreator a solo los archivos fuente
set(CMAKE_SKIP_BUILD_RPATH TRUE)
