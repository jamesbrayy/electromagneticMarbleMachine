from PyQt6.QtWidgets import (QApplication, QDialog, QGridLayout, QGroupBox, QHBoxLayout, QLabel, QPushButton, QDoubleSpinBox, QStyleFactory, QCheckBox, QLineEdit)
from PyQt6 import QtGui
import pyqtgraph
from numpy import log, log10, floor, sqrt
import os; import sys
roundTo = 3; width = 900; alternate = False; height = 241

class WidgetGallery(QDialog):
    def __init__(self, parent=None):
        super(WidgetGallery, self).__init__(parent)

        self.originalPalette = QApplication.palette()
        QApplication.setPalette(self.originalPalette)

        self.roundingCheck = QCheckBox("round to 3 significant figures")
        self.roundingCheck.setChecked(True)
        self.roundingCheck.toggled.connect(self.check)
        
        self.alternateCheck = QCheckBox("use kilometres per hour")
        self.alternateCheck.setChecked(False)
        self.alternateCheck.toggled.connect(self.check)
        
        self.createLeftGroupBox()
        self.createMiddleGroupBox()
        self.createrightGroupBox()

        baseLayout = QHBoxLayout()
        baseLayout.addWidget(self.roundingCheck)
        baseLayout.addWidget(self.alternateCheck)
        baseLayout.setStretch(1, 1)

        mainLayout = QGridLayout()
        mainLayout.addLayout(baseLayout, 2, 0, 1, 3)
        mainLayout.addWidget(self.leftGroupBox, 1, 0)
        mainLayout.addWidget(self.middleGroupBox, 1, 1)
        mainLayout.addWidget(self.rightGroupBox, 1, 2)
        mainLayout.setRowStretch(1, 1)
        mainLayout.setColumnStretch(0, 1)
        mainLayout.setColumnStretch(1, 1)
        mainLayout.setColumnStretch(2, 1)
        self.setLayout(mainLayout)

        self.setWindowTitle("firing capacitor calculator")
        self.setWindowIcon(QtGui.QIcon(os.path.dirname(os.path.realpath(__file__)) + os.path.sep + "ruhRohRaggy.png"))
        self.setMinimumSize(width, height)
        QApplication.setStyle(QStyleFactory.create("WindowsVista"))

    def check(self):
        global roundTo; global alternate
        if (self.roundingCheck.isChecked()): roundTo = 3
        else: roundTo = False
        if (self.alternateCheck.isChecked()): alternate = True
        else: alternate = False
        self.calcs()
    
    def calcs(self):
            units = "m/s"
            V = voltage.value(); C = capacitance.value()*10**-6; Eff = efficiency.value()*10**-2; m = mass.value()*10**-3
            R = resistance.value(); sV = safeVoltage.value()
            energy = (0.5*C*(V**2))*Eff
            speed = sqrt((2*energy)/m)
            height = energy/(9.81*m)
            time = -R*C*log(sV/V)
            power = (V**2)/R
            if alternate == True:
                speed *= 3.6
                units = "km/h"
            if roundTo != False:
                energy = round(energy, -int(floor(log10(abs(energy)))) + (roundTo - 1))
                speed = round(speed, -int(floor(log10(abs(speed)))) + (roundTo - 1))
                height = round(height, -int(floor(log10(abs(height)))) + (roundTo - 1))
                time = round(time, -int(floor(log10(abs(time)))) + (roundTo - 1))
                power = round(power, -int(floor(log10(abs(power)))) + (roundTo - 1))
            energyOutput.setText(f"{str(energy)} J")
            speedOutput.setText(f"{str(speed)} {units}")
            heightOutput.setText(f"{str(height)} m")
            timeOutput.setText(f"{str(time)} s")
            powerOutput.setText(f"{str(power)} W")
    
    def createLeftGroupBox(self):
        global voltage; global capacitance; global efficiency; global mass
        self.leftGroupBox = QGroupBox("input variables")

        voltageLabel = QLabel("voltage")
        voltageLabel.setMaximumWidth(50)
        voltage = QDoubleSpinBox(self.leftGroupBox, minimum = 0, maximum = 1000000000, value = 405, suffix = " V", decimals = 0)
        capacitanceLabel = QLabel("capacitance"); capacitanceLabel.setMaximumWidth(68)
        capacitance = QDoubleSpinBox(self.leftGroupBox, minimum = 0, maximum = 1000000000, value = 3400, suffix = " uF", decimals = 0)
        efficiencyLabel = QLabel("efficiency"); efficiencyLabel.setMaximumWidth(60)
        efficiency = QDoubleSpinBox(self.leftGroupBox, minimum = 0, maximum = 100, value = 1, suffix = " %")
        massLabel = QLabel("mass"); massLabel.setMaximumWidth(60)
        mass = QDoubleSpinBox(self.leftGroupBox, minimum = 0, maximum = 1000000000, value = 18, suffix = " g", decimals = 1)
        submitValues = QPushButton("calculate", clicked = lambda: self.calcs())
        
        layout = QGridLayout()
        layout.addWidget(voltageLabel, 0, 0, 1, 2)
        layout.addWidget(voltage, 0, 1, 1, 2)
        layout.addWidget(capacitanceLabel, 1, 0, 1, 2)
        layout.addWidget(capacitance, 1, 1, 1, 2)
        layout.addWidget(efficiencyLabel, 2, 0, 1, 2)
        layout.addWidget(efficiency, 2, 1, 1, 2)
        layout.addWidget(massLabel, 3, 0, 1, 2)
        layout.addWidget(mass, 3, 1, 1, 2)
        layout.addWidget(submitValues, 4, 0, 1, 3)
        
        layout.setRowStretch(7, 1)
        self.leftGroupBox.setLayout(layout)

    def createMiddleGroupBox(self):
        global energyOutput; global speedOutput; global heightOutput
        self.middleGroupBox = QGroupBox("coil outputs")
        
        energyLabel = QLabel("energy:")
        energyOutput = QLineEdit("", readOnly = True)
        speedLabel = QLabel("speed:")
        speedOutput = QLineEdit("", readOnly = True)
        heightLabel = QLabel("height:")
        heightOutput = QLineEdit("", readOnly = True)

        layout = QGridLayout()
        layout.addWidget(energyLabel, 0, 0)
        layout.addWidget(energyOutput, 0, 1)
        layout.addWidget(speedLabel, 1, 0)
        layout.addWidget(speedOutput, 1, 1)
        layout.addWidget(heightLabel, 2, 0)
        layout.addWidget(heightOutput, 2, 1)
        layout.setRowStretch(5, 1)
        self.middleGroupBox.setLayout(layout)

    def createrightGroupBox(self):
        global resistance; global safeVoltage
        global timeOutput; global powerOutput
        self.rightGroupBox = QGroupBox("bleeder resistor")

        resistanceLabel = QLabel("resistance"); resistanceLabel.setMaximumWidth(68)
        resistance = QDoubleSpinBox(self.rightGroupBox, minimum = 0, maximum = 1000000000, value = 1000, suffix = " Ω", decimals = 0)
        safeVoltageLabel = QLabel("safe voltage"); safeVoltageLabel.setMaximumWidth(68)
        safeVoltage = QDoubleSpinBox(self.rightGroupBox, minimum = 0, maximum = 1000000000, value = 48, suffix = " V", decimals = 0)

        timeLabel = QLabel("discharge time:")
        timeOutput = QLineEdit("", readOnly = True)
        powerLabel = QLabel("maximum power:")
        powerOutput = QLineEdit("", readOnly = True)
        
        layout = QGridLayout()
        layout.addWidget(resistanceLabel, 0, 0, 1, 2)
        layout.addWidget(resistance, 0, 1, 1, 2)
        layout.addWidget(safeVoltageLabel, 1, 0, 1, 2)
        layout.addWidget(safeVoltage, 1, 1, 1, 2)
        layout.addWidget(timeLabel, 2, 0, 1, 2)
        layout.addWidget(timeOutput, 2, 1, 1, 2)
        layout.addWidget(powerLabel, 3, 0, 1, 2)
        layout.addWidget(powerOutput, 3, 1, 1, 2)
        
        layout.setRowStretch(5, 1)
        self.rightGroupBox.setLayout(layout)

if __name__ == "__main__":
    app = QApplication(sys.argv)
    gallery = WidgetGallery()
    gallery.show()
    print('a')
    sys.exit(app.exec())